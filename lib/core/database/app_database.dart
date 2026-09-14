import 'database_migrations.dart';
import 'database_tables.dart';

abstract interface class AppDatabase {
  int get version;
  bool get isOpen;

  Future<void> open();
  Future<void> close();
  Future<List<Map<String, Object?>>> query(
    String table, {
    Map<String, Object?> where = const {},
    List<String>? columns,
  });
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  );
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String conflictColumn = 'id',
  });
  Future<void> update(String table, String id, Map<String, Object?> values);
  Future<void> delete(String table, String id);
  Future<void> deleteWhere(String table, Map<String, Object?> where);
  Future<void> deleteWhereIn(String table, String column, Iterable<Object?> values);
  void beginBatch();
  Future<void> endBatch();
}

/// Deterministic in-memory adapter for tests and isolated callers.
///
/// Production startup uses the SQLCipher-backed implementation while the
/// application depends only on [AppDatabase].
class InMemoryAppDatabase implements AppDatabase {
  InMemoryAppDatabase({int initialVersion = 0}) : _version = initialVersion;

  int _version;
  bool _isOpen = false;
  final Map<String, List<Map<String, Object?>>> _tables = {
    for (final table in DatabaseTables.all) table: <Map<String, Object?>>[],
  };

  @override
  int get version => _version;
  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (_isOpen) return;
    if (DatabaseMigrations.statementsForUpgrade(_version).isNotEmpty) {
      _version = DatabaseMigrations.latestVersion;
    }
    _isOpen = true;
  }

  @override
  Future<void> close() async => _isOpen = false;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    Map<String, Object?> where = const {},
    List<String>? columns,
  }) async {
    _ensureReady(table);
    return [
      for (final row in _tables[table]!)
        if (where.entries.every((entry) => row[entry.key] == entry.value))
          columns == null
              ? Map<String, Object?>.from(row)
              : {for (final column in columns) column: row[column]},
    ];
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    _ensureReady(table);
    final row = Map<String, Object?>.from(values);
    _tables[table]!.add(row);
    return Map<String, Object?>.from(row);
  }

  @override
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String conflictColumn = 'id',
  }) async {
    _ensureReady(table);
    final key = values[conflictColumn];
    final index = _tables[table]!.indexWhere((row) => row[conflictColumn] == key);
    if (index < 0) {
      _tables[table]!.add(Map<String, Object?>.from(values));
    } else {
      _tables[table]![index] = {..._tables[table]![index], ...values};
    }
    return Map<String, Object?>.from(values);
  }

  @override
  Future<void> update(String table, String id, Map<String, Object?> values) async {
    _ensureReady(table);
    final rows = _tables[table]!;
    final index = rows.indexWhere((row) => row['id'] == id || row['key'] == id);
    if (index < 0) throw StateError('No record with id "$id" exists in $table.');
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> delete(String table, String id) async {
    _ensureReady(table);
    _tables[table]!.removeWhere((row) => row['id'] == id || row['key'] == id);
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object?> where) async {
    _ensureReady(table);
    _tables[table]!.removeWhere(
      (row) => where.entries.every((entry) => row[entry.key] == entry.value),
    );
  }

  @override
  Future<void> deleteWhereIn(String table, String column, Iterable<Object?> values) async {
    _ensureReady(table);
    final selected = values.toSet();
    if (selected.isEmpty) return;
    _tables[table]!.removeWhere((row) => selected.contains(row[column]));
  }

  @override
  void beginBatch() {}
  @override
  Future<void> endBatch() async {}

  void _ensureReady(String table) {
    if (!_isOpen) throw StateError('Database is not open.');
    if (!_tables.containsKey(table)) throw ArgumentError.value(table, 'table', 'Unknown table.');
  }
}
