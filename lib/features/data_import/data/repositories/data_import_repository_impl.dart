import 'dart:convert';

import 'package:excel/excel.dart';

import '../datasources/data_import_data_source.dart';
import '../../domain/entities/field_rule.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/repositories/data_import_repository.dart';

class DataImportRepositoryImpl implements DataImportRepository {
  DataImportRepositoryImpl(this._dataSource);

  final DataImportDataSource _dataSource;

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
    final conflicts = _headerConflicts(parsed.first);
    final columns = _uniqueHeaders(parsed.first);
    final rows = <Map<String, String>>[];
    for (final cells in parsed.skip(1)) {
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      rows.add({
        for (var index = 0; index < columns.length; index++)
          columns[index]: index < cells.length ? cells[index].trim() : '',
      });
    }
    return ImportedTable(
      columns: columns,
      rows: rows,
      headerConflicts: conflicts,
    );
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

    final rawHeaders = [for (final cell in sheet.rows.first) _cellText(cell)];
    final conflicts = _headerConflicts(rawHeaders);
    final columns = _uniqueHeaders(rawHeaders);
    final rows = <Map<String, String>>[];
    for (final cells in sheet.rows.skip(1)) {
      final values = [for (final cell in cells) _cellText(cell)];
      if (values.every((value) => value.trim().isEmpty)) continue;
      rows.add({
        for (var index = 0; index < columns.length; index++)
          columns[index]: index < values.length ? values[index].trim() : '',
      });
    }
    return ImportedTable(
      columns: columns,
      rows: rows,
      headerConflicts: conflicts,
    );
  }

  @override
  Future<ImportedTable> saveForProject(
    String projectId,
    ImportedTable table,
  ) async {
    final existing = await getForProject(projectId);
    final merged = _mergeIncomingColumns(existing, table);
    await _dataSource.appendRecords(projectId, merged);
    return getForProject(projectId);
  }

  @override
  Future<ImportedTable> updateForProject(
    String projectId,
    ImportedTable table,
  ) async {
    await _dataSource.replaceRecords(projectId, table);
    return getForProject(projectId);
  }

  @override
  Future<ImportedTable> getForProject(String projectId) async {
    final rows = await _dataSource.getRecordRows(projectId);
    rows.sort((left, right) {
      final leftNumber = _rowNumber(left['row_number']);
      final rightNumber = _rowNumber(right['row_number']);
      return leftNumber.compareTo(rightNumber);
    });
    final fieldRules = await _dataSource.getRecordFieldRules(projectId);
    final maps = <Map<String, String>>[];
    final recordIds = <String?>[];
    final columns = List<String>.of(
      await _dataSource.getRecordColumns(projectId),
    );
    for (final row in rows) {
      final storedColumns = row['columns_json'];
      if (storedColumns is String && storedColumns.isNotEmpty) {
        final decodedColumns = jsonDecode(storedColumns);
        if (decodedColumns is List) {
          for (final column in decodedColumns) {
            final name = column.toString();
            if (name.isNotEmpty && !columns.contains(name)) columns.add(name);
          }
        }
      }
      final raw = row['data_json'];
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          maps.add(
            decoded.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          );
          recordIds.add(row['id']?.toString());
        }
      }
    }
    for (final row in maps) {
      for (final key in row.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }
    final canonicalColumns = <String>[];
    final canonicalByName = <String, String>{};
    for (final column in columns) {
      final name = column.trim();
      final normalized = _normalizeHeader(name);
      if (name.isEmpty || normalized.isEmpty) continue;
      canonicalByName.putIfAbsent(normalized, () {
        canonicalColumns.add(name);
        return name;
      });
    }
    final canonicalRules = <String, FieldRule>{};
    for (final entry in fieldRules.entries) {
      final target = canonicalByName[_normalizeHeader(entry.key)];
      if (target != null) canonicalRules.putIfAbsent(target, () => entry.value);
    }
    return ImportedTable(
      columns: canonicalColumns,
      fieldRules: canonicalRules,
      recordIds: recordIds,
      rows: [
        for (final row in maps)
          {
            for (final column in canonicalColumns)
              column: _canonicalRowValue(row, column, canonicalByName),
          },
      ],
    );
  }

  String _canonicalRowValue(
    Map<String, String> row,
    String column,
    Map<String, String> canonicalByName,
  ) {
    for (final entry in row.entries) {
      if (canonicalByName[_normalizeHeader(entry.key)] == column &&
          entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }
    return '';
  }

  ImportedTable _mergeIncomingColumns(
    ImportedTable existing,
    ImportedTable incoming,
  ) {
    // Older versions could leave duplicate column definitions in settings
    // after rows were deleted. Treat those definitions as aliases of the
    // first column instead of making the next import fail permanently.
    final existingColumns = <String>[];
    final existingByName = <String, List<String>>{};
    for (final column in existing.columns) {
      final name = column.trim();
      if (name.isEmpty) continue;
      final normalized = _normalizeHeader(name);
      if (normalized.isEmpty) continue;
      final aliases = existingByName.putIfAbsent(normalized, () => []);
      if (aliases.isEmpty) existingColumns.add(name);
      aliases.add(name);
    }

    final mappedNames = <String, String>{};
    final targets = <String>{};
    for (final column in incoming.columns) {
      final name = column.trim();
      if (name.isEmpty) continue;
      final normalized = _normalizeHeader(name);
      final matches = existingByName[normalized] ?? const <String>[];
      final target = matches.isEmpty ? name : matches.first;
      if (!targets.add(target)) {
        // A repeated incoming header has already been disambiguated by the
        // parser (for example, Name and Name 2). If a legacy table still
        // maps both names to one target, keep the later value under a safe
        // unique column rather than showing an error to the user.
        var suffix = 2;
        var fallback = '$name $suffix';
        while (targets.contains(fallback) ||
            existingColumns.any(
              (column) => _normalizeHeader(column) == _normalizeHeader(fallback),
            )) {
          suffix++;
          fallback = '$name $suffix';
        }
        mappedNames[name] = fallback;
        targets.add(fallback);
        continue;
      }
      mappedNames[name] = target;
    }

    final columns = <String>[...existingColumns];
    for (final target in mappedNames.values) {
      if (!columns.contains(target)) columns.add(target);
    }
    final fieldRules = Map<String, dynamic>.from(existing.fieldRules);
    for (final entry in incoming.fieldRules.entries) {
      final target = mappedNames[entry.key] ?? entry.key;
      fieldRules[target] = entry.value;
    }
    return ImportedTable(
      columns: columns,
      fieldRules: {
        for (final entry in fieldRules.entries)
          if (entry.value is FieldRule) entry.key: entry.value as FieldRule,
      },
      rows: [
        for (final row in incoming.rows)
          {
            for (final column in columns)
              column: _incomingValue(row, mappedNames, column) ?? '',
          },
      ],
    );
  }

  String? _incomingValue(
    Map<String, String> row,
    Map<String, String> mappedNames,
    String target,
  ) {
    for (final entry in mappedNames.entries) {
      if (entry.value == target) return row[entry.key];
    }
    return null;
  }

  int _rowNumber(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  String _normalizeHeader(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');

  List<String> _headerConflicts(List<String> headers) {
    final seen = <String>{};
    final conflicts = <String>{};
    for (final header in headers) {
      final name = header.trim();
      if (name.isEmpty) continue;
      final normalized = _normalizeHeader(name);
      if (!seen.add(normalized)) conflicts.add(name);
    }
    return conflicts.toList();
  }

  List<String> _uniqueHeaders(List<String> headers) {
    final result = <String>[];
    for (var index = 0; index < headers.length; index++) {
      final base = headers[index].trim().isEmpty
          ? 'Column ${index + 1}'
          : headers[index].trim();
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
      TextCellValue(:final value) => value.text ?? value.toString(),
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
