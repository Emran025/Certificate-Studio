import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/export_file_writer.dart';
import '../../../../core/files/project_asset_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../certificates/data/services/template_bytes.dart';

class WorkspaceTransferService {
  WorkspaceTransferService(this._database, {this.keyStorage});

  final AppDatabase _database;
  final KeyStorage? keyStorage;

  static const _profileFormat = 'cstudio-profile-v1';
  static const _profileManifest = 'institution.json';
  static const _profileKeys = 'keys.json';
  static const _profileSettings = 'settings.json';
  static const _projectFormat = 'cstudio-project-v2';
  static const _fieldPositionsName = 'field_positons.json';
  static const _legacyFieldPositionsName = 'field_positions.json';
  static const _dataRowsName = 'data_rows.csv';
  static const _projectMetadataName = 'project.json';
  static const _spacingName = 'app_spacing.dart';

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
      ..addFile(_jsonFile(_profileManifest, {
        'format': _profileFormat,
        'institution': institutions.first,
      }))
      ..addFile(_jsonFile(_profileKeys, {
        'format': _profileFormat,
        'institution_public_key': publicKey,
        'institution_private_key': privateKey,
      }))
      ..addFile(_jsonFile(_profileSettings, {
        'format': _profileFormat,
        'settings': settings.isEmpty ? null : settings.first,
      }));
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

  Future<bool> importProfile() async {
    final storage = keyStorage;
    if (storage == null) {
      throw StateError('Secure key storage is not available.');
    }
    final file = await _pickFile(['cszp']);
    if (file == null) return false;
    final archive = ZipDecoder().decodeBytes(file.bytes!);
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
    final institution = _decodeArchiveJson(entries, _profileManifest)['institution'];
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

  Future<String?> exportSignatures(String institutionId) async {
    final projects = await _database.query(
      DatabaseTables.projects,
      where: {'institution_id': institutionId},
      columns: ['id'],
    );
    final signatures = <Map<String, Object?>>[];
    for (final project in projects) {
      signatures.addAll(
        await _database.query(
          DatabaseTables.signatures,
          where: {'project_id': project['id']},
        ),
      );
    }
    return _saveJson(
      title: 'Export signature settings',
      name: 'certificate-studio-signatures.json',
      payload: {'format': 'cstudio-signatures-v1', 'signatures': signatures},
    );
  }

  Future<int> importSignatures() async {
    final file = await _pickFile(['json']);
    if (file == null) return 0;
    final decoded = jsonDecode(utf8.decode(file.bytes!));
    if (decoded is! Map || decoded['format'] != 'cstudio-signatures-v1') {
      throw const FormatException('Unsupported signature settings file.');
    }
    final values = decoded['signatures'];
    if (values is! List) {
      throw const FormatException('Invalid signatures payload.');
    }
    var imported = 0;
    for (final value in values) {
      if (value is! Map) continue;
      await _database.upsert(
        DatabaseTables.signatures,
        Map<String, Object?>.from(value),
      );
      imported++;
    }
    return imported;
  }

  Future<String?> exportProject(String projectId) async {
    final project = await _one(DatabaseTables.projects, {'id': projectId});
    if (project == null) {
      throw StateError('The selected project no longer exists.');
    }

    final templateId = project['template_id'] as String?;
    final template = templateId == null
        ? null
        : await _one(DatabaseTables.templates, {'id': templateId});
    final backgroundPath = template?['file_path']?.toString();
    final backgroundBytes = backgroundPath == null || backgroundPath.isEmpty
        ? null
        : await readTemplateBytes(backgroundPath);
    if (backgroundBytes == null || backgroundBytes.isEmpty) {
      throw StateError(
        'The project does not have a readable background image.',
      );
    }

    final fields = await _database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': projectId},
    );
    final layouts = await _database.query(
      DatabaseTables.certificateLayouts,
      where: {'project_id': projectId},
    );
    final signatures = await _database.query(
      DatabaseTables.signatures,
      where: {'project_id': projectId},
    );
    final students = await _database.query(
      DatabaseTables.students,
      where: {'project_id': projectId},
    );
    final archive = Archive()
      ..addFile(
        _jsonFile(_projectMetadataName, {
          'format': _projectFormat,
          'project': project,
          'template': template,
          'signatures': signatures,
          'layouts': layouts,
        }),
      )
      ..addFile(
        _jsonFile(_fieldPositionsName, {
          'format': _projectFormat,
          'fields': fields,
          'layouts': layouts,
        }),
      )
      ..addFile(
        ArchiveFile(
          _backgroundName(template, project),
          backgroundBytes.length,
          backgroundBytes,
        ),
      )
      ..addFile(
        ArchiveFile(
          _spacingName,
          utf8.encode(_appSpacingSource).length,
          utf8.encode(_appSpacingSource),
        ),
      )
      ..addFile(
        ArchiveFile(
          _dataRowsName,
          utf8.encode(_studentsToCsv(students)).length,
          utf8.encode(_studentsToCsv(students)),
        ),
      );

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null || encoded.isEmpty) {
      throw StateError('The project archive could not be created.');
    }
    return saveExportBytes(
      dialogTitle: 'Export project',
      fileName:
          '${_safeFileName(project['name']?.toString() ?? 'project')}.czip',
      extension: 'czip',
      bytes: Uint8List.fromList(encoded),
    );
  }

  Future<String?> importProject(String institutionId) async {
    final file = await _pickFile(['czip', 'json']);
    if (file == null) return null;
    final extension = (file.extension ?? '').toLowerCase();
    if (extension == 'json') {
      return _importLegacyJson(institutionId, file.bytes!);
    }

    final archive = ZipDecoder().decodeBytes(file.bytes!);
    final entries = <String, List<int>>{
      for (final entry in archive.files)
        if (entry.isFile) entry.name: entry.content,
    };
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

    final backgroundEntry = entries.entries
        .where((entry) => _isBackground(entry.key))
        .firstOrNull;
    final backgroundPath = backgroundEntry == null
        ? null
        : await saveProjectBackground(
            fileName: '${projectId}_${backgroundEntry.key.split('/').last}',
            bytes: backgroundEntry.value,
          );
    if (backgroundEntry != null && backgroundPath == null) {
      throw UnsupportedError(
        'Project background import is unavailable on this platform.',
      );
    }

    await _clearProjectData(projectId);
    final template = metadata['template'];
    if (template is Map && backgroundPath != null) {
      final templateRow = Map<String, Object?>.from(template)
        ..['file_path'] = backgroundPath
        ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _database.upsert(DatabaseTables.templates, templateRow);
      project['template_id'] = templateRow['id'];
    }
    await _database.upsert(DatabaseTables.projects, project);

    await _upsertRows(
      DatabaseTables.signatures,
      metadata['signatures'],
      projectId,
    );
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
    await _upsertRows(
      DatabaseTables.certificateLayouts,
      fieldPayload['layouts'],
      projectId,
    );
    final csv = entries[_dataRowsName];
    if (csv != null) await _replaceStudentsFromCsv(projectId, utf8.decode(csv));
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
    await _clearProjectData(projectId);
    await _database.upsert(DatabaseTables.projects, project);
    for (final table in [
      DatabaseTables.signatures,
      DatabaseTables.students,
      DatabaseTables.certificateFields,
      DatabaseTables.certificateLayouts,
    ]) {
      await _upsertRows(table, decoded[table], projectId);
    }
    return projectId;
  }

  Future<void> _clearProjectData(String projectId) async {
    for (final table in [
      DatabaseTables.signatures,
      DatabaseTables.students,
      DatabaseTables.certificateFields,
      DatabaseTables.certificateLayouts,
    ]) {
      await _database.deleteWhere(table, {'project_id': projectId});
    }
  }

  Future<void> _upsertRows(
    String table,
    Object? value,
    Object? projectId,
  ) async {
    if (value is! List) return;
    for (final raw in value) {
      if (raw is! Map) continue;
      await _database.upsert(table, {
        ...Map<String, Object?>.from(raw),
        'project_id': projectId,
      });
    }
  }

  Future<void> _replaceStudentsFromCsv(String projectId, String csv) async {
    final rows = _csvToRows(csv);
    await _database.deleteWhere(DatabaseTables.students, {
      'project_id': projectId,
    });
    for (var index = 0; index < rows.length; index++) {
      final values = rows[index];
      await _database.insert(DatabaseTables.students, {
        'id': 'student-${DateTime.now().microsecondsSinceEpoch}-$index',
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
      'student_class',
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return null;
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

  Future<String?> _saveJson({
    required String title,
    required String name,
    required Map<String, Object?> payload,
  }) {
    final bytes = utf8.encode(jsonEncode(payload));
    return saveExportBytes(
      dialogTitle: title,
      fileName: name,
      extension: 'json',
      bytes: bytes,
    );
  }

  String _backgroundName(
    Map<String, Object?>? template,
    Map<String, Object?> project,
  ) {
    final format = template?['format']?.toString().toLowerCase();
    final extension = ['png', 'jpg', 'jpeg'].contains(format) ? format! : 'png';
    return 'background.$extension';
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

  String _studentsToCsv(List<Map<String, Object?>> students) {
    final maps = <Map<String, String>>[];
    final columns = <String>[];
    for (final student in students) {
      final raw = student['data_json'];
      if (raw is! String) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      final values = decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
      maps.add(values);
      for (final key in values.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }
    return [
      columns.map(_csvCell).join(','),
      for (final row in maps)
        columns.map((column) => _csvCell(row[column] ?? '')).join(','),
    ].join('\r\n');
  }

  List<Map<String, String>> _csvToRows(String input) {
    final lines = input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    if (lines.isEmpty || lines.first.trim().isEmpty) return [];
    final headers = _parseCsvLine(lines.first);
    return [
      for (final line in lines.skip(1))
        if (line.trim().isNotEmpty)
          {
            for (var index = 0; index < headers.length; index++)
              headers[index]: index < _parseCsvLine(line).length
                  ? _parseCsvLine(line)[index]
                  : '',
          },
    ];
  }

  String _csvCell(String value) => value.contains(RegExp(r'[,"]|\r|\n'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }
    result.add(buffer.toString());
    return result;
  }
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
