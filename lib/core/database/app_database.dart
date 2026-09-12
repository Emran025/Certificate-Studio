import 'database_migrations.dart';
import 'database_tables.dart';

abstract interface class AppDatabase {
  int get version;
  bool get isOpen;

  Future<void> open();
  Future<void> close();
  Future<List<Map<String, Object?>>> query(String table, {Map<String, Object?> where = const {}});
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values);
  Future<void> update(String table, String id, Map<String, Object?> values);
  Future<void> delete(String table, String id);
}

/// Deterministic local adapter used until a platform SQLCipher driver is wired.
///
/// The application depends only on [AppDatabase], so Android/iOS/Desktop/Web
/// implementations can use SQLCipher, IndexedDB, or WASM without changing the
/// domain and repository layers.
class InMemoryAppDatabase implements AppDatabase {
  InMemoryAppDatabase({int initialVersion = 0}) : _version = initialVersion;

  int _version;
  bool _isOpen = false;
  final Map<String, List<Map<String, Object?>>> _tables = {
    for (final table in [
      DatabaseTables.institutions,
      DatabaseTables.projects,
      DatabaseTables.templates,
      DatabaseTables.fonts,
      DatabaseTables.signatures,
      DatabaseTables.students,
      DatabaseTables.certificateFields,
      DatabaseTables.certificateLayouts,
      DatabaseTables.certificates,
      DatabaseTables.generationJobs,
      DatabaseTables.generationItems,
      DatabaseTables.verificationRecords,
      DatabaseTables.settings,
    ])
      table: <Map<String, Object?>>[],
  };

  @override
  int get version => _version;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (_isOpen) return;
    final migrationStatements = DatabaseMigrations.statementsForUpgrade(_version);
    if (migrationStatements.isNotEmpty) {
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
  }) async {
    _ensureReady(table);
    return [
      for (final row in _tables[table]!)
        if (where.entries.every((entry) => row[entry.key] == entry.value))
          Map<String, Object?>.from(row),
    ];
  }

  @override
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values) async {
    _ensureReady(table);
    final row = Map<String, Object?>.from(values);
    _tables[table]!.add(row);
    return Map<String, Object?>.from(row);
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
    _tables[table]!.removeWhere((row) => row['id'] == id);
  }

  void _ensureReady(String table) {
    if (!_isOpen) throw StateError('Database is not open.');
    if (!_tables.containsKey(table)) throw ArgumentError.value(table, 'table', 'Unknown table.');
  }
}
