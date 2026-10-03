import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/imported_table.dart';
import '../../../../shared/utils/field_identifier.dart';
import 'data_import_data_source.dart';

class DataImportDataSourceImpl implements DataImportDataSource {
  DataImportDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<void> replaceRecords(String projectId, ImportedTable table) async {
    _database.beginBatch();
    try {
      await _database.deleteWhere(DatabaseTables.records, {
        'project_id': projectId,
      });
      await _database.upsert(
        DatabaseTables.settings,
        {
          'key': _columnsKey(projectId),
          'value_json': jsonEncode(table.columns),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictColumn: 'key',
      );
      for (var index = 0; index < table.rows.length; index++) {
        final values = table.rows[index];
        final classSource = values.entries
            .where((entry) {
              final id = canonicalFieldClassId(entry.key);
              return id == 'class' ||
                  id == 'class_name' ||
                  id == 'record_class' ||
                  id == 'الصف' ||
                  id == 'الفصل' ||
                  id == 'الشعبة';
            })
            .map((entry) => entry.value.trim())
            .firstWhere(
              (value) => value.isNotEmpty,
              orElse: () => '${index + 1}',
            );
        final now = DateTime.now().toUtc().toIso8601String();
        await _database.insert(DatabaseTables.records, {
          'id': 'record-${DateTime.now().microsecondsSinceEpoch}-$index',
          'project_id': projectId,
          'class_name': classSource,
          'data_json': jsonEncode(values),
          'columns_json': jsonEncode(table.columns),
          'row_number': index + 1,
          'created_at': now,
          'updated_at': now,
        });
      }
    } finally {
      await _database.endBatch();
    }
  }

  @override
  Future<List<Map<String, Object?>>> getRecordRows(String projectId) =>
      _database.query(
        DatabaseTables.records,
        where: {'project_id': projectId},
        columns: ['data_json', 'columns_json'],
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
    return decoded is List ? [for (final value in decoded) value.toString()] : const [];
  }

  String _columnsKey(String projectId) => 'records-columns:$projectId';
}
