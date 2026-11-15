import 'field_rule.dart';
import 'imported_table.dart';

enum ImportMergeDecision { keepExisting, useImported, keepBoth }

class ImportConflict {
  const ImportConflict({
    required this.incomingIndex,
    required this.existingIndex,
    required this.identity,
    required this.existingRow,
    required this.incomingRow,
    required this.exactDuplicate,
  });

  final int incomingIndex;
  final int existingIndex;
  final String identity;
  final Map<String, String> existingRow;
  final Map<String, String> incomingRow;
  final bool exactDuplicate;
}

class ImportMergePlan {
  const ImportMergePlan({
    required this.existing,
    required this.incoming,
    required this.conflicts,
    required this.newRowCount,
    required this.reusedColumnCount,
    required this.newColumnCount,
  });

  final ImportedTable existing;
  final ImportedTable incoming;
  final List<ImportConflict> conflicts;
  final int newRowCount;
  final int reusedColumnCount;
  final int newColumnCount;

  bool get hasConflicts => conflicts.isNotEmpty;

  ImportedTable apply(
    Map<int, ImportMergeDecision> decisions, {
    ImportMergeDecision defaultDecision = ImportMergeDecision.keepExisting,
  }) {
    final columns = <String>[...existing.columns];
    final existingByName = <String, String>{
      for (final column in existing.columns) _normalize(column): column,
    };
    final incomingToExisting = <String, String>{};
    for (final incomingColumn in incoming.columns) {
      final target = existingByName[_normalize(incomingColumn)];
      if (target == null) {
        columns.add(incomingColumn);
        existingByName[_normalize(incomingColumn)] = incomingColumn;
        incomingToExisting[incomingColumn] = incomingColumn;
      } else {
        incomingToExisting[incomingColumn] = target;
      }
    }

    final rows = <Map<String, String>>[
      for (final row in existing.rows) _expandRow(row, columns, const {}),
    ];
    final recordIds = <String?>[...existing.recordIds];
    final conflictByIncoming = {
      for (final conflict in conflicts) conflict.incomingIndex: conflict,
    };

    for (
      var incomingIndex = 0;
      incomingIndex < incoming.rows.length;
      incomingIndex++
    ) {
      final row = _expandRow(
        incoming.rows[incomingIndex],
        columns,
        incomingToExisting,
      );
      final conflict = conflictByIncoming[incomingIndex];
      if (conflict == null) {
        rows.add(row);
        recordIds.add(null);
        continue;
      }
      final decision = decisions[incomingIndex] ?? defaultDecision;
      switch (decision) {
        case ImportMergeDecision.keepExisting:
          break;
        case ImportMergeDecision.useImported:
          rows[conflict.existingIndex] = row;
          break;
        case ImportMergeDecision.keepBoth:
          rows.add(row);
          recordIds.add(null);
      }
    }

    final rules = <String, FieldRule>{...existing.fieldRules};
    for (final entry in incoming.fieldRules.entries) {
      final target = incomingToExisting[entry.key] ?? entry.key;
      rules[target] = entry.value;
    }
    return ImportedTable(
      columns: columns,
      rows: rows,
      recordIds: recordIds,
      fieldRules: rules,
    );
  }

  Map<String, String> _expandRow(
    Map<String, String> row,
    List<String> columns,
    Map<String, String> mapping,
  ) => {for (final column in columns) column: _valueFor(row, column, mapping)};

  String _valueFor(
    Map<String, String> row,
    String target,
    Map<String, String> mapping,
  ) {
    if (row.containsKey(target)) return row[target] ?? '';
    for (final entry in row.entries) {
      final mapped = mapping[entry.key];
      if (mapped == target) return entry.value;
    }
    return '';
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
}

class ImportMergePlanner {
  const ImportMergePlanner._();

  static ImportMergePlan plan({
    required ImportedTable existing,
    required ImportedTable incoming,
  }) {
    final conflicts = <ImportConflict>[];
    final usedExisting = <int>{};
    final identityColumns = _identityColumns(
      existing.columns,
      incoming.columns,
    );

    for (
      var incomingIndex = 0;
      incomingIndex < incoming.rows.length;
      incomingIndex++
    ) {
      final incomingRow = incoming.rows[incomingIndex];
      final match = _findMatch(
        existing,
        incomingRow,
        identityColumns,
        usedExisting,
      );
      if (match == null) continue;
      usedExisting.add(match.index);
      conflicts.add(
        ImportConflict(
          incomingIndex: incomingIndex,
          existingIndex: match.index,
          identity: match.identity,
          existingRow: existing.rows[match.index],
          incomingRow: incomingRow,
          exactDuplicate: match.exact,
        ),
      );
    }

    final existingNames = {
      for (final column in existing.columns) _normalize(column),
    };
    final incomingNames = {
      for (final column in incoming.columns) _normalize(column),
    };
    return ImportMergePlan(
      existing: existing,
      incoming: incoming,
      conflicts: conflicts,
      newRowCount: incoming.rows.length - conflicts.length,
      reusedColumnCount: incomingNames.intersection(existingNames).length,
      newColumnCount: incomingNames.difference(existingNames).length,
    );
  }

  static _Match? _findMatch(
    ImportedTable existing,
    Map<String, String> incomingRow,
    List<String> identityColumns,
    Set<int> usedExisting,
  ) {
    for (var index = 0; index < existing.rows.length; index++) {
      if (usedExisting.contains(index)) continue;
      final existingRow = existing.rows[index];
      final identity = _identity(existingRow, identityColumns);
      final incomingIdentity = _identity(incomingRow, identityColumns);
      if (identity == null || identity != incomingIdentity) continue;
      final exact = _sameData(existingRow, incomingRow);
      return _Match(index: index, identity: identity, exact: exact);
    }
    return null;
  }

  static List<String> _identityColumns(
    List<String> existing,
    List<String> incoming,
  ) {
    final all = [...existing, ...incoming];
    const preferred = [
      'id',
      'recordid',
      'studentid',
      'identifier',
      'رقم',
      'معرف',
      'اسم',
      'name',
      'fullname',
      'studentname',
      'recipient',
    ];
    final result = <String>[];
    for (final preferredName in preferred) {
      for (final column in all) {
        if (_normalize(column) == _normalize(preferredName) &&
            !result.contains(column)) {
          result.add(column);
        }
      }
    }
    final classColumn = all.where(
      (column) => {
        'class',
        'classname',
        'recordclass',
        'الفصل',
        'الشعبة',
        'الصف',
      }.contains(_normalize(column)),
    );
    if (result.isNotEmpty && classColumn.isNotEmpty) {
      result.add(classColumn.first);
    }
    return result;
  }

  static String? _identity(Map<String, String> row, List<String> columns) {
    if (columns.isEmpty) return null;
    final values = <String>[];
    for (final column in columns) {
      final value = row.entries
          .where((entry) => _normalize(entry.key) == _normalize(column))
          .map((entry) => entry.value.trim().toLowerCase())
          .firstOrNull;
      if (value == null || value.isEmpty) return null;
      values.add(value);
    }
    return values.join('|');
  }

  static bool _sameData(Map<String, String> left, Map<String, String> right) {
    final keys = {
      for (final key in [...left.keys, ...right.keys]) _normalize(key),
    };
    for (final key in keys) {
      final leftValue =
          left.entries
              .where((entry) => _normalize(entry.key) == key)
              .map((entry) => entry.value.trim().toLowerCase())
              .firstOrNull ??
          '';
      final rightValue =
          right.entries
              .where((entry) => _normalize(entry.key) == key)
              .map((entry) => entry.value.trim().toLowerCase())
              .firstOrNull ??
          '';
      if (leftValue != rightValue) return false;
    }
    return true;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
}

class _Match {
  const _Match({
    required this.index,
    required this.identity,
    required this.exact,
  });

  final int index;
  final String identity;
  final bool exact;
}
