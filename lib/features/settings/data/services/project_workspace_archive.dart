import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/files/project_asset_store.dart';
import '../../../../core/files/project_workspace_storage.dart';
import '../../../certificates/data/services/template_bytes.dart';

/// The canonical, versioned representation of a project workspace package.
///
/// The package contains logical database rows and relative asset paths; it never
/// copies the device-local SQLCipher database or private signing keys.
class ProjectWorkspaceArchive {
  ProjectWorkspaceArchive(
    this.database, {
    CertificateArtifactStore? artifactStore,
  }) : artifactStore = artifactStore ?? WorkspaceCertificateArtifactStore();

  final AppDatabase database;
  final CertificateArtifactStore artifactStore;

  static const format = 'cstudio-project-workspace';
  static const version = 1;
  static const manifestPath = 'workspace/manifest.json';
  static const maxArchiveBytes = 256 * 1024 * 1024;
  static const _legacyProjectFormat = 'cstudio-project-v2';

  Future<Uint8List> exportProject(String projectId) async {
    final project = await _one(DatabaseTables.projects, {'id': projectId});
    if (project == null)
      throw StateError('The selected project no longer exists.');

    final templateId = project['template_id']?.toString();
    final template = templateId == null
        ? null
        : await _one(DatabaseTables.templates, {'id': templateId});
    if (templateId != null && template == null) {
      throw StateError('The selected project template is missing.');
    }

    final fields = await database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': projectId},
    );
    final records = await database.query(
      DatabaseTables.records,
      where: {'project_id': projectId},
    );
    final fonts = await _referencedFonts(project, fields);
    final certificates = await database.query(
      DatabaseTables.certificates,
      where: {'project_id': projectId},
    );
    final certificateIds = certificates.map((row) => row['id']).toSet();
    final verifications = certificateIds.isEmpty
        ? <Map<String, Object?>>[]
        : await database.query(DatabaseTables.verificationRecords);
    final selectedVerifications = verifications
        .where((row) => certificateIds.contains(row['certificate_id']))
        .toList();
    final settings = await database.query(DatabaseTables.settings);
    final projectSettings = settings.where((row) {
      final key = row['key']?.toString() ?? '';
      return key == 'records-columns:$projectId';
    }).toList();

    final rows = <String, List<Map<String, Object?>>>{
      'projects': [_portableRow(project)],
      'templates': [if (template != null) _portableRow(template)],
      'fonts': [for (final font in fonts) _portableRow(font)],
      'records': [for (final row in records) _portableRow(row)],
      'certificate_fields': [for (final row in fields) _portableRow(row)],
      'certificates': [for (final row in certificates) _portableRow(row)],
      'verification_records': [
        for (final row in selectedVerifications) _portableRow(row),
      ],
      'settings': [for (final row in projectSettings) _portableRow(row)],
    };

    final files = <String, List<int>>{};
    final rowFiles = <String, String>{
      'projects': 'workspace/data/project.json',
      'templates': 'workspace/data/templates.json',
      'fonts': 'workspace/data/fonts.json',
      'records': 'workspace/data/records.json',
      'certificate_fields': 'workspace/design/fields.json',
      'certificates': 'workspace/data/certificates.json',
      'verification_records': 'workspace/verification/records.json',
      'settings': 'workspace/data/settings.json',
    };
    final assets = <Map<String, Object?>>[];
    Future<void> addAsset({
      required String table,
      required Map<String, Object?> row,
      required String field,
      required String relativePath,
      required List<int> bytes,
      String? contentType,
    }) async {
      if (bytes.isEmpty) return;
      final fullPath = 'workspace/$relativePath';
      files[fullPath] = bytes;
      assets.add({
        'table': table,
        'row_id': row['id'],
        'field': field,
        'path': fullPath,
        'length': bytes.length,
        'sha256': await _sha256(bytes),
        if (contentType != null) 'content_type': contentType,
      });
    }

    if (template != null) {
      final bytes = await _readPath(template['file_path']?.toString());
      if (bytes == null || bytes.isEmpty) {
        throw StateError('The project template image cannot be read.');
      }
      final extension = _extension(
        template['file_path']?.toString(),
        template['format']?.toString() ?? 'png',
      );
      await addAsset(
        table: 'templates',
        row: template,
        field: 'file_path',
        relativePath: 'assets/templates/${_token(template['id']!)}.$extension',
        bytes: bytes,
        contentType: _mimeType(extension),
      );
    }

    final projectLogo = await _readPath(project['logo_path']?.toString());
    if (project['logo_path'] is String &&
        (project['logo_path'] as String).isNotEmpty &&
        (projectLogo == null || projectLogo.isEmpty)) {
      throw StateError('The project logo image cannot be read.');
    }
    if (projectLogo != null && projectLogo.isNotEmpty) {
      final extension = _extension(project['logo_path']?.toString(), 'png');
      await addAsset(
        table: 'projects',
        row: project,
        field: 'logo_path',
        relativePath: 'assets/logos/project-${_token(projectId)}.$extension',
        bytes: projectLogo,
        contentType: _mimeType(extension),
      );
    }

    for (final font in fonts) {
      final embedded = font['font_bytes'];
      final bytes = embedded is List<int>
          ? embedded
          : await _readPath(font['file_path']?.toString());
      if (bytes == null || bytes.isEmpty) {
        throw StateError('The project font "${font['name']}" cannot be read.');
      }
      final extension = _extension(
        font['file_path']?.toString(),
        font['format']?.toString() ?? 'ttf',
      );
      await addAsset(
        table: 'fonts',
        row: font,
        field: 'file_path',
        relativePath: 'assets/fonts/${_token(font['id']!)}.$extension',
        bytes: bytes,
        contentType: _fontMimeType(extension),
      );
    }

    for (final certificate in certificates) {
      for (final field in ['file_path', 'image_path']) {
        final reference = certificate[field]?.toString();
        if (reference == null || reference.isEmpty) continue;
        final bytes = await artifactStore.read(reference);
        if (bytes == null || bytes.isEmpty) {
          throw StateError('A generated certificate file cannot be read.');
        }
        final extension = field == 'file_path' ? 'pdf' : 'png';
        await addAsset(
          table: 'certificates',
          row: certificate,
          field: field,
          relativePath:
              'outputs/certificates/${_token(certificate['id']!)}/certificate.$extension',
          bytes: bytes,
          contentType: extension == 'pdf' ? 'application/pdf' : 'image/png',
        );
      }
    }

    for (final asset in assets) {
      final table = asset['table']! as String;
      final rowId = asset['row_id'];
      final field = asset['field']! as String;
      final row = rows[table]!.firstWhere(
        (candidate) => candidate['id'] == rowId,
      );
      row[field] = 'workspace://${asset['path']}';
      if (table == 'fonts' && field == 'file_path') row['font_bytes'] = null;
    }
    for (final entry in rowFiles.entries) {
      files[entry.value] = _jsonBytes(rows[entry.key]!);
    }
    files['workspace/README.md'] = utf8.encode('''
# Certificate Studio project workspace

This folder contains a portable snapshot of project data, design, assets, generated certificate files, and a versioned manifest. The application database and private signing keys are device-local and are not included.
''');

    final legacyMetadata = <String, Object?>{
      'format': _legacyProjectFormat,
      'project': {..._portableRow(project), 'logo_path': null},
      'template': template == null
          ? null
          : {
              ..._portableRow(template),
              'file_path':
                  'background.${_extension(template['file_path']?.toString(), template['format']?.toString() ?? 'png')}',
            },
    };
    files['project.json'] = _jsonBytes(legacyMetadata);
    files['field_positons.json'] = _jsonBytes({
      'format': _legacyProjectFormat,
      'fields': fields.map(_portableRow).toList(),
    });
    if (template != null) {
      final backgroundAsset = assets.firstWhere(
        (asset) => asset['table'] == 'templates',
      );
      final imagePath = backgroundAsset['path']! as String;
      final imageBytes = files[imagePath]!;
      final extension = imagePath.split('.').last;
      files['background.$extension'] = imageBytes;
    }
    files['app_spacing.dart'] = utf8.encode(_appSpacingSource);
    files['data_rows.csv'] = utf8.encode(_recordsToCsv(records));

    final manifestFiles = <Map<String, Object?>>[];
    for (final entry in files.entries) {
      if (entry.key.startsWith('workspace/')) {
        manifestFiles.add({
          'path': entry.key,
          'length': entry.value.length,
          'sha256': await _sha256(entry.value),
        });
      }
    }
    final manifest = <String, Object?>{
      'format': format,
      'version': version,
      'database_schema_version': DatabaseSchema.version,
      'project_id': projectId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'rows': rowFiles,
      'assets': assets,
      'files': manifestFiles,
    };
    files[manifestPath] = _jsonBytes(manifest);

    await ensureProjectWorkspace(projectId);
    for (final entry in files.entries) {
      if (entry.key.startsWith('workspace/')) {
        await saveProjectWorkspaceFile(
          projectId: projectId,
          relativePath: entry.key.substring('workspace/'.length),
          bytes: entry.value,
        );
      }
    }

    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null || encoded.isEmpty) {
      throw StateError('The project workspace archive could not be created.');
    }
    return Uint8List.fromList(encoded);
  }

  Future<String> importProject({
    required String institutionId,
    required List<int> archiveBytes,
  }) async {
    if (archiveBytes.isEmpty || archiveBytes.length > maxArchiveBytes) {
      throw const FormatException('The project archive is empty or too large.');
    }
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final entries = <String, List<int>>{};
    var totalBytes = 0;
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      _validateArchivePath(entry.name);
      if (entries.containsKey(entry.name)) {
        throw FormatException('The project archive repeats ${entry.name}.');
      }
      final content = entry.content;
      totalBytes += content.length;
      if (totalBytes > maxArchiveBytes) {
        throw const FormatException('The project archive is too large.');
      }
      entries[entry.name] = content;
    }
    if (!entries.containsKey(manifestPath)) {
      throw const FormatException('No portable workspace manifest was found.');
    }

    final rawManifest = _decodeJson(entries, manifestPath);
    if (rawManifest is! Map) {
      throw const FormatException('Invalid workspace manifest.');
    }
    final manifest = Map<String, Object?>.from(rawManifest);
    if (manifest['format'] != format || manifest['version'] != version) {
      throw const FormatException('Unsupported project workspace format.');
    }
    final schemaVersion = manifest['database_schema_version'];
    if (schemaVersion is! int || schemaVersion > DatabaseSchema.version) {
      throw const FormatException(
        'This project was created by a newer app version.',
      );
    }
    final projectId = manifest['project_id'];
    if (projectId is! String || projectId.isEmpty) {
      throw const FormatException('The workspace manifest has no project id.');
    }
    final declaredFiles = await _validateManifestFiles(manifest, entries);
    final rowPaths = manifest['rows'];
    if (rowPaths is! Map)
      throw const FormatException('Workspace rows are missing.');
    for (final table in const [
      'projects',
      'templates',
      'fonts',
      'records',
      'certificate_fields',
      'certificates',
      'verification_records',
      'settings',
    ]) {
      final path = rowPaths[table];
      if (path is! String || !declaredFiles.contains(path)) {
        throw FormatException('The $table rows are not checksummed.');
      }
    }

    List<Map<String, Object?>> loadRows(String table) {
      final path = rowPaths[table];
      if (path is! String) throw FormatException('Missing $table row file.');
      final decoded = _decodeJson(entries, path);
      if (decoded is! List) throw FormatException('Invalid $table row file.');
      return [
        for (final item in decoded)
          if (item is Map)
            Map<String, Object?>.from(item)
          else
            throw FormatException('Invalid row in $table.'),
      ];
    }

    final projects = loadRows('projects');
    if (projects.length != 1 || projects.single['id'] != projectId) {
      throw const FormatException(
        'The project row does not match the manifest.',
      );
    }
    final templates = loadRows('templates');
    final fonts = loadRows('fonts');
    final records = loadRows('records');
    final fields = loadRows('certificate_fields');
    final certificates = loadRows('certificates');
    final verifications = loadRows('verification_records');
    final settings = loadRows('settings');
    final targetInstitution = await _one(DatabaseTables.institutions, {
      'id': institutionId,
    });
    if (targetInstitution == null) {
      throw StateError('The destination institution does not exist.');
    }

    final project = projects.single;
    final importedAt = DateTime.now().toUtc().toIso8601String();
    project
      ..['institution_id'] = institutionId
      ..['updated_at'] = importedAt;
    for (final row in [...templates, ...fonts, ...certificates, ...settings]) {
      row['updated_at'] = importedAt;
    }
    for (final row in verifications) {
      row['institution_id'] = institutionId;
    }
    final sharedIdRemap = await _remapSharedAssets(
      project,
      templates,
      fonts,
      fields,
    );
    await _rewriteWorkspaceRows(entries, manifest, rowPaths, {
      'projects': projects,
      'templates': templates,
      'fonts': fonts,
      'records': records,
      'certificate_fields': fields,
      'certificates': certificates,
      'verification_records': verifications,
      'settings': settings,
    }, sharedIdRemap);
    final templateId = project['template_id'];
    if (templateId != null &&
        !templates.any((row) => row['id'] == templateId)) {
      throw const FormatException(
        'The selected project template row is missing.',
      );
    }
    _validateRows(
      projectId,
      project,
      templates,
      fonts,
      records,
      fields,
      certificates,
      verifications,
      settings,
    );
    await _ensureNoConflicts(
      projectId,
      templates,
      fonts,
      records,
      fields,
      certificates,
      verifications,
      settings,
    );

    final assetRecords = manifest['assets'];
    if (assetRecords is! List)
      throw const FormatException('Workspace assets are missing.');
    final savedPaths = <String, String>{};
    final externalWorkspaceFiles = <Map<String, String>>[];
    const workspaceRootCreated = true;
    try {
      await ensureProjectWorkspace(projectId);
      for (final rawAsset in assetRecords) {
        if (rawAsset is! Map)
          throw const FormatException('Invalid workspace asset entry.');
        final asset = Map<String, Object?>.from(rawAsset);
        final path = asset['path'];
        final table = asset['table'];
        final rowId = asset['row_id'];
        final field = asset['field'];
        if (path is! String ||
            table is! String ||
            rowId is! String ||
            field is! String) {
          throw const FormatException('Invalid workspace asset reference.');
        }
        _validateAssetReference(table, field, path);
        final resolvedRowId = sharedIdRemap['$table/$rowId'] ?? rowId;
        final assetKey = '$table/$resolvedRowId/$field';
        if (savedPaths.containsKey(assetKey)) {
          throw const FormatException(
            'A workspace row has duplicate asset references.',
          );
        }
        final bytes = entries[path];
        if (bytes == null)
          throw FormatException('Workspace asset $path is missing.');
        final ownerRows = _rowsForTable(
          table,
          project,
          templates,
          fonts,
          records,
          fields,
          certificates,
          verifications,
          settings,
        );
        final owner = ownerRows
            .where((row) => row['id'] == resolvedRowId)
            .firstOrNull;
        if (owner == null)
          throw FormatException('Asset owner $rowId is missing.');
        final localPath = await _saveAsset(
          projectId,
          table,
          owner,
          field,
          path,
          bytes,
        );
        savedPaths[assetKey] = localPath;
        final extension = path.split('.').last.toLowerCase();
        if (table == 'templates') {
          externalWorkspaceFiles.add({
            'projectId': 'template-library',
            'relativePath':
                'assets/templates/template-${_token(projectId)}-${_token(resolvedRowId)}.$extension',
          });
        } else if (table == 'fonts') {
          externalWorkspaceFiles.add({
            'projectId': 'font-library',
            'relativePath':
                'assets/fonts/font-${_token(projectId)}-${_token(resolvedRowId)}.$extension',
          });
        }
        if (table == 'fonts' && field == 'file_path') {
          owner['font_bytes'] = Uint8List.fromList(bytes);
        }
      }
      for (final entry in entries.entries) {
        if (entry.key.startsWith('workspace/')) {
          await saveProjectWorkspaceFile(
            projectId: projectId,
            relativePath: entry.key.substring('workspace/'.length),
            bytes: entry.value,
          );
        }
      }

      for (final row in templates) {
        _applyAssetPath(row, 'templates', 'file_path', savedPaths);
      }
      for (final row in fonts) {
        _applyAssetPath(row, 'fonts', 'file_path', savedPaths);
      }
      _applyAssetPath(project, 'projects', 'logo_path', savedPaths);
      for (final row in certificates) {
        _applyArtifactPath(row, 'file_path', savedPaths);
        _applyArtifactPath(row, 'image_path', savedPaths);
      }

      var transactionStarted = false;
      try {
        database.beginBatch();
        transactionStarted = true;
      } on UnsupportedError {
        // Web storage adapters currently do not provide SQL transactions.
      }
      try {
        for (final row in templates) {
          await database.insert(DatabaseTables.templates, row);
        }
        for (final row in fonts) {
          await database.insert(DatabaseTables.fonts, row);
        }
        await database.insert(DatabaseTables.projects, project);
        for (final row in records) {
          await database.insert(DatabaseTables.records, row);
        }
        for (final row in fields) {
          await database.insert(DatabaseTables.certificateFields, row);
        }
        for (final row in certificates) {
          await database.insert(DatabaseTables.certificates, row);
        }
        for (final row in verifications) {
          await database.insert(DatabaseTables.verificationRecords, row);
        }
        for (final row in settings) {
          await database.insert(DatabaseTables.settings, row);
        }
      } finally {
        if (transactionStarted) await database.endBatch();
      }
      return projectId;
    } on Object {
      try {
        await _rollbackPartialImport(projectId, templates, fonts, settings);
      } on Object {
        // Preserve the original import error if best-effort cleanup also fails.
      }
      for (final entry in savedPaths.entries) {
        if (entry.key.startsWith('certificates/')) {
          try {
            await artifactStore.delete(entry.value);
          } on Object {
            // Keep the original import failure if an artifact cannot be removed.
          }
        }
      }
      for (final file in externalWorkspaceFiles) {
        try {
          await deleteProjectWorkspaceFile(
            projectId: file['projectId']!,
            relativePath: file['relativePath']!,
          );
        } on Object {
          // Preserve the original error when cleanup cannot access a file.
        }
      }
      try {
        if (workspaceRootCreated) await deleteProjectWorkspace(projectId);
      } on Object {
        // Preserve the original error when the workspace cannot be deleted.
      }
      rethrow;
    }
  }

  Future<void> _rollbackPartialImport(
    String projectId,
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fonts,
    List<Map<String, Object?>> settings,
  ) async {
    await database.deleteWhere(DatabaseTables.verificationRecords, {
      'project_id': projectId,
    });
    await database.deleteWhere(DatabaseTables.certificates, {
      'project_id': projectId,
    });
    await database.deleteWhere(DatabaseTables.records, {
      'project_id': projectId,
    });
    await database.deleteWhere(DatabaseTables.certificateFields, {
      'project_id': projectId,
    });
    await database.deleteWhere(DatabaseTables.projects, {'id': projectId});
    for (final row in [...templates, ...fonts]) {
      final id = row['id'];
      if (id is String)
        await database.deleteWhere(
          row.containsKey('family')
              ? DatabaseTables.fonts
              : DatabaseTables.templates,
          {'id': id},
        );
    }
    for (final row in settings) {
      final key = row['key'];
      if (key is String) {
        await database.deleteWhere(DatabaseTables.settings, {'key': key});
      }
    }
  }

  Future<List<Map<String, Object?>>> _referencedFonts(
    Map<String, Object?> project,
    List<Map<String, Object?>> fields,
  ) async {
    final ids = <String>{
      for (final field in fields)
        if (field['font_id'] is String &&
            (field['font_id'] as String).isNotEmpty)
          field['font_id']! as String,
    };
    final rawSettings = project['settings_json'];
    if (rawSettings is String && rawSettings.isNotEmpty) {
      final settings = jsonDecode(rawSettings);
      if (settings is Map && settings['font_id'] is String) {
        ids.add(settings['font_id'] as String);
      }
    }
    final result = <Map<String, Object?>>[];
    for (final id in ids) {
      final font = await _one(DatabaseTables.fonts, {'id': id});
      if (font == null) throw StateError('A project font ($id) is missing.');
      result.add(font);
    }
    return result;
  }

  Future<Map<String, String>> _remapSharedAssets(
    Map<String, Object?> project,
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fonts,
    List<Map<String, Object?>> fields,
  ) async {
    final remapped = <String, String>{};
    var counter = 0;
    Future<void> remapRows(
      String table,
      List<Map<String, Object?>> rows,
    ) async {
      final seenIds = <Object?>{};
      for (final row in rows) {
        final originalId = row['id'];
        if (originalId is! String || !seenIds.add(originalId)) {
          throw const FormatException('Shared asset rows have invalid IDs.');
        }
        if (await _one(table, {'id': originalId}) == null) continue;
        var newId = '';
        do {
          counter++;
          newId = 'import-${DateTime.now().microsecondsSinceEpoch}-$counter';
        } while (await _one(table, {'id': newId}) != null);
        row['id'] = newId;
        remapped['$table/$originalId'] = newId;
      }
    }

    await remapRows(DatabaseTables.templates, templates);
    await remapRows(DatabaseTables.fonts, fonts);
    final oldTemplateId = project['template_id'];
    if (oldTemplateId is String) {
      project['template_id'] =
          remapped['${DatabaseTables.templates}/$oldTemplateId'] ??
          oldTemplateId;
    }
    for (final field in fields) {
      final fontId = field['font_id'];
      if (fontId is String) {
        field['font_id'] =
            remapped['${DatabaseTables.fonts}/$fontId'] ?? fontId;
      }
    }
    final settingsJson = project['settings_json'];
    if (settingsJson is String && settingsJson.isNotEmpty) {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map && decoded['font_id'] is String) {
        final oldFontId = decoded['font_id'] as String;
        final newFontId = remapped['${DatabaseTables.fonts}/$oldFontId'];
        if (newFontId != null) {
          decoded['font_id'] = newFontId;
          project['settings_json'] = jsonEncode(decoded);
        }
      }
    }
    return remapped;
  }

  Future<void> _rewriteWorkspaceRows(
    Map<String, List<int>> entries,
    Map<String, Object?> manifest,
    Map<dynamic, dynamic> rowPaths,
    Map<String, List<Map<String, Object?>>> rows,
    Map<String, String> remapped,
  ) async {
    final updatedPaths = <String>{};
    for (final entry in rows.entries) {
      final path = rowPaths[entry.key] as String;
      entries[path] = _jsonBytes(entry.value);
      updatedPaths.add(path);
    }
    final rawAssets = manifest['assets']! as List;
    manifest['assets'] = [
      for (final raw in rawAssets)
        if (raw is Map)
          () {
            final asset = Map<String, Object?>.from(raw);
            final table = asset['table'];
            final rowId = asset['row_id'];
            if (table is String && rowId is String) {
              asset['row_id'] = remapped['$table/$rowId'] ?? rowId;
            }
            return asset;
          }()
        else
          raw,
    ];
    final files = manifest['files']! as List;
    final updatedFiles = <Object?>[];
    for (final raw in files) {
      if (raw is! Map) {
        updatedFiles.add(raw);
        continue;
      }
      final file = Map<String, Object?>.from(raw);
      final path = file['path'];
      if (path is String && updatedPaths.contains(path)) {
        final bytes = entries[path]!;
        file['length'] = bytes.length;
        file['sha256'] = await _sha256(bytes);
      }
      updatedFiles.add(file);
    }
    manifest['files'] = updatedFiles;
    entries[manifestPath] = _jsonBytes(manifest);
  }

  Future<void> _ensureNoConflicts(
    String projectId,
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fonts,
    List<Map<String, Object?>> records,
    List<Map<String, Object?>> fields,
    List<Map<String, Object?>> certificates,
    List<Map<String, Object?>> verifications,
    List<Map<String, Object?>> settings,
  ) async {
    final conflicts = <String>[];
    Future<void> check(
      String table,
      Iterable<Map<String, Object?>> rows,
    ) async {
      for (final row in rows) {
        final id = row['id'];
        if (id is String && await _one(table, {'id': id}) != null) {
          conflicts.add('$table:$id');
        }
      }
    }

    if (await _one(DatabaseTables.projects, {'id': projectId}) != null) {
      conflicts.add('projects:$projectId');
    }
    await check(DatabaseTables.templates, templates);
    await check(DatabaseTables.fonts, fonts);
    await check(DatabaseTables.records, records);
    await check(DatabaseTables.certificateFields, fields);
    await check(DatabaseTables.certificates, certificates);
    await check(DatabaseTables.verificationRecords, verifications);
    for (final row in settings) {
      if (row['key'] is String &&
          await _one(DatabaseTables.settings, {'key': row['key']}) != null) {
        conflicts.add('settings:${row['key']}');
      }
    }
    if (conflicts.isNotEmpty) {
      throw StateError(
        'Import stopped to protect existing data. Conflicting IDs: ${conflicts.take(5).join(', ')}${conflicts.length > 5 ? ', …' : ''}.',
      );
    }
  }

  void _validateRows(
    String projectId,
    Map<String, Object?> project,
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fonts,
    List<Map<String, Object?>> records,
    List<Map<String, Object?>> fields,
    List<Map<String, Object?>> certificates,
    List<Map<String, Object?>> verifications,
    List<Map<String, Object?>> settings,
  ) {
    _requireKeys(project, const [
      'id',
      'institution_id',
      'name',
      'project_key_reference',
      'created_at',
      'updated_at',
    ], 'project');
    for (final row in templates) {
      _requireKeys(row, const [
        'id',
        'name',
        'file_path',
        'width',
        'height',
        'dpi',
        'format',
        'created_at',
        'updated_at',
      ], 'template');
    }
    for (final row in fonts) {
      _requireKeys(row, const [
        'id',
        'name',
        'family',
        'file_path',
        'format',
        'created_at',
        'updated_at',
      ], 'font');
    }
    for (final row in records) {
      _requireKeys(row, const [
        'id',
        'project_id',
        'class_name',
        'data_json',
        'row_number',
        'created_at',
        'updated_at',
      ], 'record');
    }
    for (final row in fields) {
      _requireKeys(row, const [
        'id',
        'project_id',
        'class_name',
        'position_json',
        'style_json',
        'created_at',
        'updated_at',
      ], 'design field');
    }
    for (final row in certificates) {
      _requireKeys(row, const [
        'id',
        'project_id',
        'record_id',
        'status',
        'created_at',
        'updated_at',
      ], 'certificate');
    }
    for (final row in verifications) {
      _requireKeys(row, const [
        'id',
        'certificate_id',
        'institution_id',
        'project_id',
        'payload_json',
        'signature',
        'created_at',
      ], 'verification record');
    }
    for (final row in settings) {
      _requireKeys(row, const [
        'key',
        'value_json',
        'updated_at',
      ], 'project setting');
    }
    for (final group in [
      templates,
      fonts,
      records,
      fields,
      certificates,
      verifications,
    ]) {
      final ids = <Object?>{};
      for (final row in group) {
        if (!ids.add(row['id'])) {
          throw const FormatException(
            'The workspace contains duplicate row IDs.',
          );
        }
      }
    }
    for (final row in [
      ...templates,
      ...fonts,
      ...records,
      ...fields,
      ...certificates,
    ]) {
      if (row['project_id'] != null && row['project_id'] != projectId) {
        throw const FormatException(
          'A workspace row belongs to a different project.',
        );
      }
    }
    final recordIds = records.map((row) => row['id']).toSet();
    final fontIds = fonts.map((row) => row['id']).toSet();
    for (final field in fields) {
      final fontId = field['font_id'];
      if (fontId != null && !fontIds.contains(fontId)) {
        throw const FormatException(
          'A design field references a missing font.',
        );
      }
    }
    final certificateIds = certificates.map((row) => row['id']).toSet();
    for (final certificate in certificates) {
      if (certificate['record_id'] is! String ||
          !recordIds.contains(certificate['record_id'])) {
        throw const FormatException(
          'A certificate references a missing recipient row.',
        );
      }
    }
    for (final verification in verifications) {
      if (verification['certificate_id'] is! String ||
          !certificateIds.contains(verification['certificate_id'])) {
        throw const FormatException(
          'A verification record references a missing certificate.',
        );
      }
    }
    for (final setting in settings) {
      final key = setting['key'];
      if (key is! String || !key.startsWith('records-columns:')) {
        throw const FormatException(
          'A workspace setting is not project-scoped.',
        );
      }
    }
  }

  List<Map<String, Object?>> _rowsForTable(
    String table,
    Map<String, Object?> project,
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fonts,
    List<Map<String, Object?>> records,
    List<Map<String, Object?>> fields,
    List<Map<String, Object?>> certificates,
    List<Map<String, Object?>> verifications,
    List<Map<String, Object?>> settings,
  ) => switch (table) {
    'projects' => [project],
    'templates' => templates,
    'fonts' => fonts,
    'records' => records,
    'certificate_fields' => fields,
    'certificates' => certificates,
    'verification_records' => verifications,
    'settings' => settings,
    _ => throw FormatException('Unsupported asset owner table $table.'),
  };

  Future<String> _saveAsset(
    String projectId,
    String table,
    Map<String, Object?> owner,
    String field,
    String packagePath,
    List<int> bytes,
  ) async {
    final extension = packagePath.split('.').last.toLowerCase();
    if (table == 'certificates') {
      return artifactStore.save(
        projectId: projectId,
        certificateId: owner['id']! as String,
        extension: field == 'file_path' ? 'pdf' : 'png',
        bytes: bytes,
      );
    }
    if (table == 'templates') {
      return await saveProjectBackground(
            projectId: 'template-library',
            fileName:
                'template-${_token(projectId)}-${_token(owner['id']!)}.$extension',
            bytes: bytes,
          ) ??
          _dataUri(packagePath, bytes);
    }
    final folder = switch (table) {
      'projects' => 'assets/logos',
      'fonts' => 'assets/fonts',
      _ => throw FormatException('Unsupported workspace asset table $table.'),
    };
    final storageProjectId = table == 'fonts' ? 'font-library' : projectId;
    final fileName = table == 'fonts'
        ? 'font-${_token(projectId)}-${_token(owner['id']!)}.$extension'
        : '${_token(owner['id']!)}.$extension';
    return await saveProjectWorkspaceFile(
          projectId: storageProjectId,
          relativePath: '$folder/$fileName',
          bytes: bytes,
        ) ??
        _dataUri(packagePath, bytes);
  }

  void _validateAssetReference(String table, String field, String path) {
    final valid = switch ((table, field)) {
      ('templates', 'file_path') =>
        path.startsWith('workspace/assets/templates/') &&
            _hasExtension(path, const {'png', 'jpg', 'jpeg', 'webp'}),
      ('projects', 'logo_path') =>
        path.startsWith('workspace/assets/logos/') &&
            _hasExtension(path, const {'png', 'jpg', 'jpeg', 'webp'}),
      ('fonts', 'file_path') =>
        path.startsWith('workspace/assets/fonts/') &&
            _hasExtension(path, const {'ttf', 'otf'}),
      ('certificates', 'file_path') =>
        path.startsWith('workspace/outputs/certificates/') &&
            _hasExtension(path, const {'pdf'}),
      ('certificates', 'image_path') =>
        path.startsWith('workspace/outputs/certificates/') &&
            _hasExtension(path, const {'png'}),
      _ => false,
    };
    if (!valid) throw FormatException('Invalid workspace asset path: $path');
  }

  void _applyAssetPath(
    Map<String, Object?> row,
    String table,
    String field,
    Map<String, String> savedPaths,
  ) {
    final path = savedPaths['$table/${row['id']}/$field'];
    final original = row[field];
    if (original is String &&
        original.startsWith('workspace://') &&
        path == null) {
      throw FormatException(
        'A packaged $field asset is missing for ${row['id']}.',
      );
    }
    if (path != null) row[field] = path;
  }

  void _applyArtifactPath(
    Map<String, Object?> row,
    String field,
    Map<String, String> savedPaths,
  ) {
    final path = savedPaths['certificates/${row['id']}/$field'];
    final original = row[field];
    if (original is String &&
        original.startsWith('workspace://') &&
        path == null) {
      throw FormatException('A packaged certificate $field file is missing.');
    }
    if (path != null) row[field] = path;
  }

  Future<Map<String, Object?>?> _one(
    String table,
    Map<String, Object?> where,
  ) async {
    final rows = await database.query(table, where: where);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<int>?> _readPath(String? path) async {
    if (path == null || path.isEmpty) return null;
    return readTemplateBytes(path);
  }

  Object? _decodeJson(Map<String, List<int>> entries, String path) {
    final bytes = entries[path];
    if (bytes == null)
      throw FormatException('Project workspace is missing $path.');
    return jsonDecode(utf8.decode(bytes));
  }

  Future<Set<String>> _validateManifestFiles(
    Map<String, Object?> manifest,
    Map<String, List<int>> entries,
  ) async {
    final files = manifest['files'];
    if (files is! List || files.isEmpty) {
      throw const FormatException('Workspace file inventory is missing.');
    }
    final assets = manifest['assets'];
    if (assets is! List) {
      throw const FormatException('Workspace asset inventory is missing.');
    }
    final declared = <String>{};
    for (final raw in files) {
      if (raw is! Map)
        throw const FormatException('Invalid workspace file inventory.');
      final path = raw['path'];
      final length = raw['length'];
      final digest = raw['sha256'];
      if (path is! String || length is! int || digest is! String) {
        throw const FormatException('Invalid workspace file checksum entry.');
      }
      _validateArchivePath(path);
      if (!path.startsWith('workspace/') || !declared.add(path)) {
        throw const FormatException(
          'Invalid or duplicated workspace file path.',
        );
      }
      final bytes = entries[path];
      if (bytes == null || bytes.length != length) {
        throw FormatException(
          'Workspace file $path is missing or has the wrong size.',
        );
      }
      if (await _sha256(bytes) != digest) {
        throw FormatException(
          'Workspace file $path failed its integrity check.',
        );
      }
    }
    for (final asset in assets) {
      if (asset is! Map ||
          asset['path'] is! String ||
          !declared.contains(asset['path'])) {
        throw const FormatException(
          'Workspace asset is not in the checksummed inventory.',
        );
      }
      final bytes = entries[asset['path'] as String]!;
      if (asset['length'] != bytes.length ||
          asset['sha256'] != await _sha256(bytes)) {
        throw FormatException(
          'Workspace asset ${asset['path']} failed validation.',
        );
      }
    }
    return declared;
  }
}

bool _hasExtension(String path, Set<String> allowed) {
  final parts = path.split('/').last.split('.');
  return parts.length > 1 && allowed.contains(parts.last.toLowerCase());
}

Map<String, Object?> _portableRow(Map<String, Object?> row) => {
  for (final entry in row.entries)
    entry.key: entry.value is Uint8List
        ? (entry.value! as Uint8List).toList()
        : entry.value,
};

void _requireKeys(
  Map<String, Object?> row,
  List<String> keys,
  String description,
) {
  for (final key in keys) {
    if (!row.containsKey(key) || row[key] == null) {
      throw FormatException('The workspace $description is missing $key.');
    }
  }
  if (row['id'] is String && (row['id'] as String).isEmpty) {
    throw FormatException('The workspace $description has an empty ID.');
  }
}

List<int> _jsonBytes(Object value) => utf8.encode(jsonEncode(value));

String _token(Object value) =>
    base64Url.encode(utf8.encode(value.toString())).replaceAll('=', '');

String _extension(String? path, String fallback) {
  final normalizedFallback = fallback.toLowerCase().replaceAll('.', '');
  if (path == null || path.isEmpty) return _safeExtension(normalizedFallback);
  if (path.startsWith('data:')) {
    final mime = path.substring(
      5,
      path.indexOf(';') < 0 ? path.length : path.indexOf(';'),
    );
    return switch (mime) {
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      'font/otf' => 'otf',
      'font/ttf' => 'ttf',
      _ => _safeExtension(normalizedFallback),
    };
  }
  final candidate = path.split('?').first.split('#').first.split('/').last;
  final dot = candidate.lastIndexOf('.');
  return _safeExtension(
    dot < 0 ? normalizedFallback : candidate.substring(dot + 1),
  );
}

String _safeExtension(String extension) =>
    RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension) ? extension : 'bin';

String _mimeType(String extension) => switch (extension) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'webp' => 'image/webp',
  _ => 'image/png',
};

String _fontMimeType(String extension) => switch (extension) {
  'otf' => 'font/otf',
  _ => 'font/ttf',
};

String _dataUri(String path, List<int> bytes) {
  final lower = path.toLowerCase();
  final mime = lower.endsWith('.pdf')
      ? 'application/pdf'
      : lower.endsWith('.ttf')
      ? 'font/ttf'
      : lower.endsWith('.otf')
      ? 'font/otf'
      : _mimeType(_extension(path, 'png'));
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

Future<String> _sha256(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

void _validateArchivePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path.contains(':')) {
    throw FormatException('Unsafe path in project archive: $path');
  }
  final segments = path.split('/');
  if (segments.any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Unsafe path in project archive: $path');
  }
}

String _recordsToCsv(List<Map<String, Object?>> records) {
  final columns = <String>[];
  for (final record in records) {
    final raw = record['data_json'];
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final key in decoded.keys) {
          if (!columns.contains(key.toString())) columns.add(key.toString());
        }
      }
    }
  }
  String escape(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  return [
    columns.map(escape).join(','),
    for (final record in records)
      (() {
        final raw = record['data_json'];
        final data = raw is String && jsonDecode(raw) is Map
            ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
            : <String, dynamic>{};
        return columns.map((column) => escape(data[column])).join(',');
      })(),
  ].join('\r\n');
}

const _appSpacingSource = '''
import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const huge = 64.0;
}
''';
