import 'dart:convert';

import 'package:excel/excel.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/repositories/data_import_repository.dart';

class DataImportRepositoryImpl implements DataImportRepository {
  DataImportRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  ImportedTable parseTable(String rawText) {
    final lines = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const ImportedTable(columns: [], rows: []);

    final delimiter = lines.first.contains('\t') ? '\t' : ',';
    final parsed = lines.map((line) => _parseLine(line, delimiter)).toList();
    final columns = _uniqueHeaders(parsed.first);
    final rows = <Map<String, String>>[];
    for (final cells in parsed.skip(1)) {
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      rows.add({
        for (var index = 0; index < columns.length; index++)
          columns[index]: index < cells.length ? cells[index].trim() : '',
      });
    }
    return ImportedTable(columns: columns, rows: rows);
  }

  @override
  ImportedTable parseExcel(List<int> bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const ImportedTable(columns: [], rows: []);
    }
    final sheet = workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      return const ImportedTable(columns: [], rows: []);
    }

    final columns = _uniqueHeaders([
      for (final cell in sheet.rows.first) _cellText(cell),
    ]);
    final rows = <Map<String, String>>[];
    for (final cells in sheet.rows.skip(1)) {
      final values = [for (final cell in cells) _cellText(cell)];
      if (values.every((value) => value.trim().isEmpty)) continue;
      rows.add({
        for (var index = 0; index < columns.length; index++)
          columns[index] = index < values.length ? values[index].trim() : '',
      });
    }
    return ImportedTable(columns: columns, rows: rows);
  }

  @override
  Future<ImportedTable> saveForProject(String projectId, ImportedTable table) async {
    final existing = await _database.query(
      DatabaseTables.students,
      where: {'project_id': projectId},
    );
    for (final row in existing) {
      final id = row['id'];
      if (id is String) await _database.delete(DatabaseTables.students, id);
    }
    for (var index = 0; index < table.rows.length; index++) {
      final values = table.rows[index];
      final className = values['class'] ?? values['Class'] ?? '${index + 1}';
      await _database.insert(DatabaseTables.students, {
        'id': 'student-${DateTime.now().microsecondsSinceEpoch}-$index',
        'project_id': projectId,
        'class_name': className,
        'data_json': jsonEncode(values),
        'row_number': index + 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    return table;
  }

  @override
  Future<ImportedTable> getForProject(String projectId) async {
    final rows = await _database.query(
      DatabaseTables.students,
      where: {'project_id': projectId},
    );
    final maps = <Map<String, String>>[];
    for (final row in rows) {
      final raw = row['data_json'];
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          maps.add(decoded.map((key, value) => MapEntry(key.toString(), value.toString())));
        }
      }
    }
    final columns = <String>[];
    for (final row in maps) {
      for (final key in row.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }
    return ImportedTable(columns: columns, rows: maps);
  }

  List<String> _uniqueHeaders(List<String> headers) {
    final result = <String>[];
    for (var index = 0; index < headers.length; index++) {
      final base = headers[index].trim().isEmpty ? 'Column ${index + 1}' : headers[index].trim();
      var candidate = base;
      var suffix = 2;
      while (result.contains(candidate)) {
        candidate = '$base $suffix';
        suffix++;
      }
      result.add(candidate);
    }
    return result;
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    return switch (value) {
      null => '',
      TextCellValue(:final value) => value,
      FormulaCellValue(:final formula) => formula,
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value.toString(),
      DateCellValue() => value.toString(),
      DateTimeCellValue() => value.toString(),
      TimeCellValue() => value.toString(),
    };
  }

  List<String> _parseLine(String line, String delimiter) {
    final cells = <String>[];
    var current = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          current.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == delimiter && !quoted) {
        cells.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(character);
      }
    }
    cells.add(current.toString());
    return cells;
  }
}
