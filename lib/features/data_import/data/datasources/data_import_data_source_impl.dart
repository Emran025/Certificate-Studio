import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../domain/entities/field_rule.dart';
import '../../domain/entities/imported_table.dart';
import '../../../../shared/utils/field_identifier.dart';
import 'data_import_data_source.dart';

class DataImportDataSourceImpl implements DataImportDataSource {
  DataImportDataSourceImpl(
    this._database, {
    CertificateArtifactStore? artifactStore,
  }) : _artifactStore =
           artifactStore ?? SharedPreferencesCertificateArtifactStore();

  final AppDatabase _database;
  final CertificateArtifactStore _artifactStore;

  @override
  Future<void> appendRecords(String projectId, ImportedTable table) async {
    final existingRows = await _database.query(
      DatabaseTables.records,
      where: {'project_id': projectId},
      columns: ['row_number'],
    );
    final lastRowNumber = existingRows.fold<int>(0, (maxRow, row) {
      final value = row['row_number'];
      final rowNumber = value is num
          ? value.toInt()
          : int.tryParse('$value') ?? 0;
      return rowNumber > maxRow ? rowNumber : maxRow;
    });

    _database.beginBatch();
    try {
      await _saveMetadata(projectId, table);
      for (var index = 0; index < table.rows.length; index++) {
        final now = DateTime.now().toUtc().toIso8601String();
        await _database.insert(
          DatabaseTables.records,
          _recordValues(
            projectId: projectId,
            id: 'record-${DateTime.now().microsecondsSinceEpoch}-$index',
            values: table.rows[index],
            columns: table.columns,
            rowNumber: lastRowNumber + index + 1,
            timestamp: now,
          ),
        );
      }
    } finally {
      await _database.endBatch();
    }
  }

  @override
  Future<void> replaceRecords(String projectId, ImportedTable table) async {
    final existingRows = await _database.query(
      DatabaseTables.records,
      where: {'project_id': projectId},
    );
    final existingById = <String, Map<String, Object?>>{
      for (final row in existingRows)
        if (row['id'] != null) row['id'].toString(): row,
    };
    final retainedIds = <String>{
      for (final id in table.recordIds)
        if (id != null && existingById.containsKey(id)) id,
    };
    final removedRows = existingRows
        .where((row) => !retainedIds.contains(row['id']?.toString()))
        .toList();
    final artifactReferences = <String>{};

    _database.beginBatch();
    try {
      await _saveMetadata(projectId, table);
      for (var index = 0; index < table.rows.length; index++) {
        final values = table.rows[index];
        final requestedId = index < table.recordIds.length
            ? table.recordIds[index]
            : null;
        final oldRecord = requestedId == null
            ? null
            : existingById[requestedId];
        final now = DateTime.now().toUtc().toIso8601String();
        final rowValues = _recordValues(
          projectId: projectId,
          id:
              oldRecord?['id']?.toString() ??
              'record-${DateTime.now().microsecondsSinceEpoch}-$index',
          values: values,
          columns: table.columns,
          rowNumber: index + 1,
          timestamp: now,
          createdAt: oldRecord?['created_at']?.toString(),
        );
        if (oldRecord == null) {
          await _database.insert(DatabaseTables.records, rowValues);
        } else {
          if (oldRecord['data_json'] != rowValues['data_json'] ||
              oldRecord['class_name'] != rowValues['class_name']) {
            await _deleteCertificatesForRecord(
              requestedId!,
              artifactReferences,
            );
          }
          await _database.update(
            DatabaseTables.records,
            requestedId!,
            rowValues..remove('id'),
          );
        }
      }
      for (final row in removedRows) {
        final recordId = row['id']?.toString();
        if (recordId != null) {
          await _deleteRecordAndDependents(recordId, artifactReferences);
        }
      }
    } finally {
      await _database.endBatch();
    }

    for (final reference in artifactReferences) {
      await _artifactStore.delete(reference);
    }
  }

  Future<void> _deleteRecordAndDependents(
    String recordId,
    Set<String> artifactReferences,
  ) async {
    await _deleteOptionalWhere('generation_items', {'record_id': recordId});
    await _deleteCertificatesForRecord(recordId, artifactReferences);
    await _database.delete(DatabaseTables.records, recordId);
  }

  Future<void> _deleteCertificatesForRecord(
    String recordId,
    Set<String> artifactReferences,
  ) async {
    final certificates = await _database.query(
      DatabaseTables.certificates,
      where: {'record_id': recordId},
    );
    for (final certificate in certificates) {
      final certificateId = certificate['id']?.toString();
      if (certificateId == null) continue;
      for (final field in ['file_path', 'image_path']) {
        final reference = certificate[field]?.toString();
        if (reference != null && reference.isNotEmpty) {
          artifactReferences.add(reference);
        }
      }
      await _database.deleteWhere(DatabaseTables.verificationRecords, {
        'certificate_id': certificateId,
      });
      await _database.delete(DatabaseTables.certificates, certificateId);
    }
  }

  Future<void> _deleteOptionalWhere(
    String table,
    Map<String, Object?> where,
  ) async {
    try {
      await _database.deleteWhere(table, where);
    } on Object catch (error) {
      final message = error.toString().toLowerCase();
      if (!message.contains('no such table') &&
          !message.contains('unknown table')) {
        rethrow;
      }
    }
  }

  Future<void> _saveMetadata(String projectId, ImportedTable table) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.upsert(DatabaseTables.settings, {
      'key': _columnsKey(projectId),
      'value_json': jsonEncode(table.columns),
      'updated_at': now,
    }, conflictColumn: 'key');
    await _database.upsert(DatabaseTables.settings, {
      'key': _fieldRulesKey(projectId),
      'value_json': jsonEncode({
        for (final entry in table.fieldRules.entries)
          entry.key: entry.value.toJson(),
      }),
      'updated_at': now,
    }, conflictColumn: 'key');
  }

  Map<String, Object?> _recordValues({
    required String projectId,
    required String id,
    required Map<String, String> values,
    required List<String> columns,
    required int rowNumber,
    required String timestamp,
    String? createdAt,
  }) {
    final classSource = values.entries
        .where((entry) {
          final fieldId = canonicalFieldClassId(entry.key);
          return fieldId == 'class' ||
              fieldId == 'class_name' ||
              fieldId == 'record_class' ||
              fieldId == 'الصف' ||
              fieldId == 'الفصل' ||
              fieldId == 'الشعبة';
        })
        .map((entry) => entry.value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '$rowNumber');
    return {
      'id': id,
      'project_id': projectId,
      'class_name': classSource,
      'data_json': jsonEncode(values),
      'columns_json': jsonEncode(columns),
      'row_number': rowNumber,
      'created_at': createdAt ?? timestamp,
      'updated_at': timestamp,
    };
  }

  @override
  Future<List<Map<String, Object?>>> getRecordRows(String projectId) =>
      _database.query(
        DatabaseTables.records,
        where: {'project_id': projectId},
        columns: ['id', 'row_number', 'data_json', 'columns_json'],
      );

  @override
  Future<List<String>> getRecordColumns(String projectId) async {
    final rows = await _database.query(
      DatabaseTables.settings,
      where: {'key': _columnsKey(projectId)},
      columns: ['value_json'],
    );
    if (rows.isEmpty) return const [];
    final raw = rows.first['value_json'];
    if (raw is! String || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? [for (final value in decoded) value.toString()]
        : const [];
  }

  @override
  Future<Map<String, FieldRule>> getRecordFieldRules(String projectId) async {
    final rows = await _database.query(
      DatabaseTables.settings,
      where: {'key': _fieldRulesKey(projectId)},
      columns: ['value_json'],
    );
    if (rows.isEmpty) return const {};
    final raw = rows.first['value_json'];
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is Map)
            entry.key.toString(): FieldRule.fromJson(
              Map<String, Object?>.from(entry.value as Map),
            ),
      };
    } on FormatException {
      return const {};
    }
  }

  String _columnsKey(String projectId) => 'records-columns:$projectId';
  String _fieldRulesKey(String projectId) => 'records-field-rules:$projectId';
}
