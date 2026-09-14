import 'dart:convert';
import 'dart:io';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import '../security/keys/institution_key_manager.dart';
import 'app_database.dart';
import 'database_migrations.dart';
import 'database_tables.dart';

/// SQLCipher-backed implementation of [AppDatabase].
///
/// SQLCipher is deliberately contained in this adapter. Repositories and
/// domain code only see the platform-neutral [AppDatabase] contract.
class PersistentAppDatabase implements AppDatabase {
  PersistentAppDatabase._(this._database, this._keyStorage);

  static const _databaseFileName = 'certificate_studio.sqlcipher.db';
  static const _legacyStorageKey = 'certificate_studio.database.v1';
  static const _databaseKeyName = 'certificate_studio.database.key.v1';

  final Database _database;
  final KeyStorage _keyStorage;
  bool _isOpen = true;
  int _batchDepth = 0;
  bool _batchFailed = false;

  static Future<PersistentAppDatabase> create({KeyStorage? keyStorage}) async {
    final storage = keyStorage ?? await PersistentKeyStorage.create();
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final key = await _loadOrCreateDatabaseKey(storage);
    final path = File('${directory.path}/$_databaseFileName').path;
    final database = sqlite3.open(path);
    try {
      _assertSqlCipher(database);
      _setKey(database, key);
      final adapter = PersistentAppDatabase._(database, storage);
      adapter._migrateSchema();
      await adapter._migrateLegacyPreferences();
      return adapter;
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  @override
  int get version => _database.userVersion;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (!_isOpen) throw StateError('A closed database cannot be reopened.');
  }

  @override
  Future<void> close() async {
    if (!_isOpen) return;
    if (_batchDepth > 0) {
      _database.execute(_batchFailed ? 'ROLLBACK' : 'COMMIT');
      _batchDepth = 0;
      _batchFailed = false;
    }
    _database.close();
    _isOpen = false;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    Map<String, Object?> where = const {},
  }) async {
    _ensureReady(table);
    final clause = _whereClause(where);
    final rows = _database.select(
      'SELECT * FROM ${_quoteIdentifier(table)}$clause',
      where.values.map(_bindValue).toList(),
    );
    return [for (final row in rows) Map<String, Object?>.from(row)];
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    _ensureReady(table);
    if (values.isEmpty) throw ArgumentError.value(values, 'values');
    final columns = values.keys.map(_quoteIdentifier).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    _run(() => _database.execute(
          'INSERT INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders)',
          values.values.map(_bindValue).toList(),
        ));
    return Map<String, Object?>.from(values);
  }

  @override
  Future<void> update(String table, String id, Map<String, Object?> values) async {
    _ensureReady(table);
    if (values.isEmpty) return;
    final assignments = values.keys.map((key) => '${_quoteIdentifier(key)} = ?').join(', ');
    _run(() {
      _database.execute(
        'UPDATE ${_quoteIdentifier(table)} SET $assignments WHERE (id = ? OR key = ?)',
        [...values.values.map(_bindValue), id, id],
      );
      if (_database.updatedRows == 0) {
        throw StateError('No record with id "$id" exists in $table.');
      }
    });
  }

  @override
  Future<void> delete(String table, String id) async {
    _ensureReady(table);
    _run(() => _database.execute(
          'DELETE FROM ${_quoteIdentifier(table)} WHERE (id = ? OR key = ?)',
          [id, id],
        ));
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object?> where) async {
    _ensureReady(table);
    final clause = _whereClause(where);
    _run(() => _database.execute(
          'DELETE FROM ${_quoteIdentifier(table)}$clause',
          where.values.map(_bindValue).toList(),
        ));
  }

  @override
  void beginBatch() {
    _ensureOpen();
    if (_batchDepth++ == 0) {
      _database.execute('BEGIN');
      _batchFailed = false;
    }
  }

  @override
  Future<void> endBatch() async {
    if (_batchDepth == 0) return;
    if (--_batchDepth == 0) {
      _database.execute(_batchFailed ? 'ROLLBACK' : 'COMMIT');
      _batchFailed = false;
    }
  }

  void _run(void Function() action) {
    try {
      action();
    } catch (_) {
      if (_batchDepth > 0) _batchFailed = true;
      rethrow;
    }
  }

  void _migrateSchema() {
    final current = version;
    if (current == DatabaseSchema.version) return;
    if (current < 0 || current > DatabaseSchema.version) {
      throw StateError('Unsupported database version: $current');
    }
    _database.execute('BEGIN');
    try {
      for (final statement in DatabaseMigrations.statementsForUpgrade(current)) {
        _database.execute(statement);
      }
      _database.execute('PRAGMA user_version = ${DatabaseSchema.version}');
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> _migrateLegacyPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_legacyStorageKey);
    if (raw == null || raw.isEmpty) return;

    final key = await _loadOrCreateDatabaseKey(_keyStorage);
    final decoded = await _decodeLegacy(raw, key);
    if (decoded == null) return;
    final tables = decoded['tables'];
    if (tables is! Map) return;

    _database.execute('BEGIN');
    try {
      for (final table in DatabaseTables.all) {
        final rows = tables[table];
        if (rows is! List) continue;
        for (final row in rows.whereType<Map>()) {
          final values = Map<String, Object?>.from(row);
          if (values.isEmpty) continue;
          final columns = values.keys.map(_quoteIdentifier).join(', ');
          final placeholders = List.filled(values.length, '?').join(', ');
          _database.execute(
            'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders)',
            values.values.map(_bindValue).toList(),
          );
        }
      }
      _database.execute('COMMIT');
      // Remove the old preference only after the SQLCipher transaction commits.
      await preferences.remove(_legacyStorageKey);
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _decodeLegacy(String raw, List<int> key) async {
    try {
      final envelope = jsonDecode(raw);
      final decoded = envelope is Map && envelope['format'] == envelopeFormat
          ? jsonDecode(utf8.decode(await decryptBytes(
              Map<String, dynamic>.from(envelope), key, aad: utf8.encode(_legacyStorageKey)))
          : envelope;
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on Object catch (error) {
      // Leave the preference untouched so a later release can retry safely.
      throw StateError('Unable to migrate the legacy local database: $error');
    }
  }

  void _ensureReady(String table) {
    _ensureOpen();
    if (!DatabaseTables.all.contains(table)) {
      throw ArgumentError.value(table, 'table', 'Unknown table.');
    }
  }

  void _ensureOpen() {
    if (!_isOpen) throw StateError('Database is not open.');
  }

  static String _whereClause(Map<String, Object?> where) => where.isEmpty
      ? ''
      : ' WHERE ${where.keys.map((key) => '${_quoteIdentifier(key)} = ?').join(' AND ')}';

  static String _quoteIdentifier(String identifier) => '"${identifier.replaceAll('"', '""')}"';

  static Object? _bindValue(Object? value) => value is bool ? (value ? 1 : 0) : value;

  static void _assertSqlCipher(Database database) {
    if (database.select('PRAGMA cipher').isEmpty) {
      throw StateError('SQLCipher is not available in the bundled SQLite library.');
    }
  }

  static void _setKey(Database database, List<int> key) {
    final hex = key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    database.execute("PRAGMA key = \"x'$hex'\"");
    database.select('SELECT count(*) FROM sqlite_master');
  }

  static Future<List<int>> _loadOrCreateDatabaseKey(KeyStorage storage) async {
    final stored = await storage.read(_databaseKeyName);
    if (stored != null && stored.isNotEmpty) {
      try {
        final key = [
          for (var i = 0; i < stored.length; i += 2)
            int.parse(stored.substring(i, i + 2), radix: 16),
        ];
        if (key.length == 32) return key;
      } on Object {
        // Replace invalid legacy values with a fresh key.
      }
    }
    final key = generateMasterKey();
    await storage.write(_databaseKeyName, key.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
    return key;
  }
}

class PersistentKeyStorage implements KeyStorage {
  const PersistentKeyStorage(this._storage);
  final FlutterSecureStorage _storage;

  static Future<PersistentKeyStorage> create() async =>
      const PersistentKeyStorage(FlutterSecureStorage());

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
