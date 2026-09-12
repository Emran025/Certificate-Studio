import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/keys/institution_key_manager.dart';
import 'app_database.dart';
import 'database_tables.dart';

/// Durable local database adapter for the application bootstrap.
///
/// Structured records remain behind [AppDatabase], so a SQLCipher-backed
/// implementation can replace this adapter without changing repositories.
class PersistentAppDatabase implements AppDatabase {
  PersistentAppDatabase._(this._preferences);

  static const _storageKey = 'certificate_studio.database.v1';
  final SharedPreferences _preferences;
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

  int _version = 0;
  bool _isOpen = false;

  static Future<PersistentAppDatabase> create() async {
    final database = PersistentAppDatabase._(
      await SharedPreferences.getInstance(),
    );
    await database.open();
    return database;
  }

  @override
  int get version => _version;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (_isOpen) return;
    final raw = _preferences.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _version = (decoded['version'] as num?)?.toInt() ?? 0;
        final storedTables = decoded['tables'];
        if (storedTables is Map<String, dynamic>) {
          for (final table in _tables.keys) {
            final rows = storedTables[table];
            if (rows is List) {
              _tables[table]!.addAll(
                rows.whereType<Map>().map(
                  (row) => Map<String, Object?>.from(row),
                ),
              );
            }
          }
        }
      }
    }
    _version = _version < DatabaseSchema.version ? DatabaseSchema.version : _version;
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    if (!_isOpen) return;
    await _persist();
    _isOpen = false;
  }

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
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    _ensureReady(table);
    final row = Map<String, Object?>.from(values);
    _tables[table]!.add(row);
    await _persist();
    return Map<String, Object?>.from(row);
  }

  @override
  Future<void> update(
    String table,
    String id,
    Map<String, Object?> values,
  ) async {
    _ensureReady(table);
    final rows = _tables[table]!;
    final index = rows.indexWhere((row) => row['id'] == id || row['key'] == id);
    if (index < 0) throw StateError('No record with id "$id" exists in $table.');
    rows[index] = {...rows[index], ...values};
    await _persist();
  }

  @override
  Future<void> delete(String table, String id) async {
    _ensureReady(table);
    _tables[table]!.removeWhere((row) => row['id'] == id);
    await _persist();
  }

  Future<void> _persist() async {
    await _preferences.setString(
      _storageKey,
      jsonEncode({'version': _version, 'tables': _tables}),
    );
  }

  void _ensureReady(String table) {
    if (!_isOpen) throw StateError('Database is not open.');
    if (!_tables.containsKey(table)) {
      throw ArgumentError.value(table, 'table', 'Unknown table.');
    }
  }
}

/// Local durable key storage. Production secure-storage adapters can implement
/// the same [KeyStorage] contract on platforms with a hardware keystore.
class PersistentKeyStorage implements KeyStorage {
  const PersistentKeyStorage(this._storage);

  final FlutterSecureStorage _storage;

  static Future<PersistentKeyStorage> create() async =>
      const PersistentKeyStorage(FlutterSecureStorage());

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
