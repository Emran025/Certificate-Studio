import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/export_file_writer.dart';
import '../../../../core/files/project_asset_store.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import 'project_workspace_archive.dart';
import 'workspace_transfer_csv.dart';

abstract interface class WorkspaceTransferServiceContract {
  Future<String?> exportProfile(String institutionId);
  Future<bool> importProfile();
  Future<String?> exportProject(String projectId);
  Future<String?> importProject(String institutionId);
}

class WorkspaceTransferService implements WorkspaceTransferServiceContract {
  WorkspaceTransferService(
    this._database, {
    this.keyStorage,
    this.artifactStore,
  });

  final AppDatabase _database;
  final KeyStorage? keyStorage;
  final CertificateArtifactStore? artifactStore;

  ProjectWorkspaceArchive get _workspaceArchive =>
      ProjectWorkspaceArchive(_database, artifactStore: artifactStore);

  Future<Uint8List> buildProjectArchiveBytes(String projectId) =>
      _workspaceArchive.exportProject(projectId);

  Future<String> importWorkspaceArchiveBytes({
    required String institutionId,
    required List<int> bytes,
  }) => _workspaceArchive.importProject(
    institutionId: institutionId,
    archiveBytes: bytes,
  );

  static const _profileFormat = 'cstudio-profile-v1';
  static const _profileManifest = 'institution.json';
  static const _profileKeys = 'keys.json';
  static const _profileSettings = 'settings.json';
  static const _projectFormat = 'cstudio-project-v2';
  static const _fieldPositionsName = 'field_positons.json';
  static const _legacyFieldPositionsName = 'field_positions.json';
  static const _dataRowsName = 'data_rows.csv';
  static const _projectMetadataName = 'project.json';

  @override
  Future<String?> exportProfile(String institutionId) async {
    final storage = keyStorage;
    if (storage == null) {
      throw StateError('Secure key storage is not available.');
    }
    final privateKey = await storage.read('institution.master_key');
    if (privateKey == null || privateKey.trim().isEmpty) {
      throw StateError('The institution private key is empty.');
    }
    final seed = _hexDecode(privateKey);
    if (seed.length != 32) {
      throw const FormatException('The institution private key is invalid.');
    }
    final publicKey = (await CertificateKeyPair.fromSeed(seed)).publicRecord();
    final institutions = await _database.query(
      DatabaseTables.institutions,
      where: {'id': institutionId},
    );
    if (institutions.isEmpty) {
      throw StateError('The institution was not found.');
    }
    final settings = await _database.query(
      DatabaseTables.settings,
      where: {'key': 'app.settings'},
    );
    final archive = Archive()
      ..addFile(
        _jsonFile(_profileManifest, {
          'format': _profileFormat,
          'institution': institutions.first,
        }),
      )
      ..addFile(
        _jsonFile(_profileKeys, {
          'format': _profileFormat,
          'institution_public_key': publicKey,
          'institution_private_key': privateKey,
        }),
      )
      ..addFile(
        _jsonFile(_profileSettings, {
          'format': _profileFormat,
          'settings': settings.isEmpty ? null : settings.first,
        }),
      );
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null || encoded.isEmpty) {
      throw StateError('The institution profile archive could not be created.');
    }
    return saveExportBytes(
      dialogTitle: 'Export institution profile',
      fileName: 'institution-profile.cszp',
      extension: 'cszp',
      bytes: Uint8List.fromList(encoded),
    );
  }

  @override
  Future<bool> importProfile() async {
    final storage = keyStorage;
    if (storage == null) {
      throw StateError('Secure key storage is not available.');
    }
    final file = await _pickFile(['cszp']);
    if (file == null) return false;
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final entries = <String, List<int>>{
      for (final entry in archive.files)
        if (entry.isFile) entry.name: entry.content,
    };
    final keys = _decodeArchiveJson(entries, _profileKeys);
    if (keys['format'] != _profileFormat) {
      throw const FormatException('Unsupported institution profile.');
    }
    final privateKey = keys['institution_private_key'];
    final publicKey = keys['institution_public_key'];
    if (privateKey is! String || privateKey.trim().isEmpty) {
      throw const FormatException('The institution private key is missing.');
    }
    if (publicKey is! Map || publicKey['public_key'] is! String) {
      throw const FormatException('The institution public key is missing.');
    }
    final seed = _hexDecode(privateKey);
    if (seed.length != 32) {
      throw const FormatException('The institution private key is invalid.');
    }
    final derived = (await CertificateKeyPair.fromSeed(seed)).publicRecord();
    if (derived['public_key'] != publicKey['public_key']) {
      throw const FormatException('The institution key pair does not match.');
    }
    final institution = _decodeArchiveJson(
      entries,
      _profileManifest,
    )['institution'];
    if (institution is! Map) {
      throw const FormatException('Institution data is missing.');
    }
    await storage.write('institution.master_key', privateKey);
    await _database.upsert(
      DatabaseTables.institutions,
      Map<String, Object?>.from(institution),
    );
    final settings = _decodeArchiveJson(entries, _profileSettings)['settings'];
    if (settings is Map) {
      await _database.upsert(
        DatabaseTables.settings,
        Map<String, Object?>.from(settings),
        conflictColumn: 'key',
      );
    }
    return true;
  }

  @override
  Future<String?> exportProject(String projectId) async {
    final project = await _one(DatabaseTables.projects, {'id': projectId});
    if (project == null) {
      throw StateError('The selected project no longer exists.');
    }
    return saveExportBytes(
      dialogTitle: 'Export project',
      fileName:
          '${_safeFileName(project['name']?.toString() ?? 'project')}.czip',
      extension: 'czip',
      bytes: await buildProjectArchiveBytes(projectId),
    );
  }

  @override
  Future<String?> importProject(String institutionId) async {
    final file = await _pickFile(['czip', 'json']);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final extension = (file.extension ?? '').toLowerCase();
    if (extension == 'json') {
      return _importLegacyJson(institutionId, bytes);
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    final entries = <String, List<int>>{
      for (final entry in archive.files)
        if (entry.isFile) entry.name: entry.content,
    };
    if (entries.containsKey(ProjectWorkspaceArchive.manifestPath)) {
      return importWorkspaceArchiveBytes(
        institutionId: institutionId,
        bytes: bytes,
      );
    }
    final metadata = _decodeArchiveJson(entries, _projectMetadataName);
    if (metadata['format'] != _projectFormat) {
      throw const FormatException('Unsupported project archive.');
    }
    final rawProject = metadata['project'];
    if (rawProject is! Map) {
      throw const FormatException('Invalid project payload.');
    }
    final project = Map<String, Object?>.from(rawProject)
      ..['institution_id'] = institutionId
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final projectId = project['id'];
    if (projectId is! String || projectId.isEmpty) {
      throw const FormatException('Project archive has no valid project id.');
    }
    if (await _one(DatabaseTables.projects, {'id': projectId}) != null) {
      throw StateError(
        'A project with this ID already exists; nothing was changed.',
      );
    }

    final backgroundEntry = entries.entries
        .where((entry) => _isBackground(entry.key))
        .firstOrNull;
    final backgroundPath = backgroundEntry == null
        ? null
        : await saveProjectBackground(
            projectId: 'template-library',
            fileName: '${projectId}_${backgroundEntry.key.split('/').last}',
            bytes: backgroundEntry.value,
          );
    if (backgroundEntry != null && backgroundPath == null) {
      throw UnsupportedError(
        'Project background import is unavailable on this platform.',
      );
    }

    final template = metadata['template'];
    if (template is Map && backgroundPath != null) {
      final templateRow = Map<String, Object?>.from(template)
        ..['file_path'] = backgroundPath
        ..['id'] = 'template-import-${DateTime.now().microsecondsSinceEpoch}'
        ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _database.insert(DatabaseTables.templates, templateRow);
      project['template_id'] = templateRow['id'];
    }
    await _database.insert(DatabaseTables.projects, project);

    final fieldPayload = _decodeArchiveJson(
      entries,
      entries.containsKey(_fieldPositionsName)
          ? _fieldPositionsName
          : _legacyFieldPositionsName,
    );
    await _upsertRows(
      DatabaseTables.certificateFields,
      fieldPayload['fields'],
      projectId,
    );
    final csv = entries[_dataRowsName];
    if (csv != null) await _replaceRecordsFromCsv(projectId, utf8.decode(csv));
    return projectId;
  }

  Future<String?> _importLegacyJson(
    String institutionId,
    List<int> bytes,
  ) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['format'] != 'cstudio-project-v1') {
      throw const FormatException('Unsupported project file.');
    }
    final rawProject = decoded['project'];
    if (rawProject is! Map) {
      throw const FormatException('Invalid project payload.');
    }
    final project = Map<String, Object?>.from(rawProject)
      ..['institution_id'] = institutionId
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final projectId = project['id'];
    if (projectId is! String) {
      throw const FormatException('Invalid project id.');
    }
    if (await _one(DatabaseTables.projects, {'id': projectId}) != null) {
      throw StateError(
        'A project with this ID already exists; nothing was changed.',
      );
    }
    await _database.insert(DatabaseTables.projects, project);
    for (final table in [
      DatabaseTables.records,
      DatabaseTables.certificateFields,
    ]) {
      await _upsertRows(table, decoded[table], projectId);
    }
    return projectId;
  }

  Future<void> _upsertRows(
    String table,
    Object? value,
    Object? projectId,
  ) async {
    if (value is! List) return;
    for (final raw in value) {
      if (raw is! Map) continue;
      final row = {...Map<String, Object?>.from(raw), 'project_id': projectId};
      final id = row['id'];
      if (id is String && await _one(table, {'id': id}) != null) {
        throw StateError('A row with ID $id already exists; import stopped.');
      }
      await _database.insert(table, row);
    }
  }

  Future<void> _replaceRecordsFromCsv(String projectId, String csv) async {
    final rows = csvToRows(csv);
    await _database.deleteWhere(DatabaseTables.records, {
      'project_id': projectId,
    });
    for (var index = 0; index < rows.length; index++) {
      final values = rows[index];
      await _database.insert(DatabaseTables.records, {
        'id': 'record-${DateTime.now().microsecondsSinceEpoch}-$index',
        'project_id': projectId,
        'class_name': _className(values, index),
        'data_json': jsonEncode(values),
        'row_number': index + 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  String _className(Map<String, String> values, int index) {
    for (final key in [
      'class',
      'class_name',
      'record_class',
      'الصف',
      'الفصل',
      'الشعبة',
    ]) {
      final value = values[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '${index + 1}';
  }

  Future<PlatformFile?> _pickFile(List<String> extensions) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return file;
  }

  Future<Map<String, Object?>?> _one(
    String table,
    Map<String, Object?> where,
  ) async {
    final rows = await _database.query(table, where: where);
    return rows.isEmpty ? null : rows.first;
  }

  ArchiveFile _jsonFile(String name, Map<String, Object?> value) {
    final bytes = utf8.encode(jsonEncode(value));
    return ArchiveFile(name, bytes.length, bytes);
  }

  Map<String, Object?> _decodeArchiveJson(
    Map<String, List<int>> entries,
    String name,
  ) {
    final bytes = entries[name];
    if (bytes == null) {
      throw FormatException('Project archive is missing $name.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw FormatException('Invalid $name.');
    }
    return Map<String, Object?>.from(decoded);
  }

  bool _isBackground(String name) {
    final lower = name.toLowerCase();
    return lower == 'background.png' ||
        lower == 'background.jpg' ||
        lower == 'background.jpeg';
  }

  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

  List<int> _hexDecode(String value) => [
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}
