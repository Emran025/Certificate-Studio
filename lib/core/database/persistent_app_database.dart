import 'dart:async';
import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/keys/institution_key_manager.dart';
import 'app_database.dart';
import 'database_tables.dart';

/// Durable local database adapter with encrypted-at-rest metadata.
///
/// The repository boundary remains platform-neutral, so a native SQLCipher or
/// IndexedDB implementation can replace this adapter without changing domain
/// code. Existing plaintext envelopes are read once and migrated on write.
class PersistentAppDatabase implements AppDatabase {
  PersistentAppDatabase._(this._preferences, this._keyStorage);

  static const _storageKey = 'certificate_studio.database.v1';
  static const _databaseKeyName = 'certificate_studio.database.key.v1';

  final SharedPreferences _preferences;
  final KeyStorage _keyStorage;
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

  late final List<int> _databaseKey;
  int _version = 0;
  bool _isOpen = false;
  Completer<void>? _persistCompleter;
  bool _persistScheduled = false;

  static Future<PersistentAppDatabase> create({KeyStorage? keyStorage}) async {
    final storage = keyStorage ?? await PersistentKeyStorage.create();
    final database = PersistentAppDatabase._(
      await SharedPreferences.getInstance(),
      storage,
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
    _databaseKey = await _loadOrCreateDatabaseKey();
    final raw = _preferences.getString(_storageKey);
    var wasPlaintext = false;
    if (raw != null && raw.isNotEmpty) {
      wasPlaintext = !_isEncrypted(raw);
      await _restore(raw);
    }
    _version = _version < DatabaseSchema.version
        ? DatabaseSchema.version
        : _version;
    _isOpen = true;
    if (wasPlaintext) await _persistNow();
  }

  @override
  Future<void> close() async {
    if (!_isOpen) return;
    await _flushPersist();
    await _persistNow();
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
    _queuePersist();
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
    if (index < 0)
      throw StateError('No record with id "$id" exists in $table.');
    rows[index] = {...rows[index], ...values};
    _queuePersist();
  }

  @override
  Future<void> delete(String table, String id) async {
    _ensureReady(table);
    _tables[table]!.removeWhere((row) => row['id'] == id || row['key'] == id);
    _queuePersist();
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object?> where) async {
    _ensureReady(table);
    _tables[table]!.removeWhere(
      (row) => where.entries.every((entry) => row[entry.key] == entry.value),
    );
    _queuePersist();
  }

  Future<List<int>> _loadOrCreateDatabaseKey() async {
    final stored = await _keyStorage.read(_databaseKeyName);
    if (stored != null && stored.isNotEmpty) {
      try {
        final key = _hexDecode(stored);
        if (key.length == 32) return key;
      } on Object {
        // Rotate an invalid legacy value below instead of failing startup.
      }
    }
    final key = generateMasterKey();
    await _keyStorage.write(_databaseKeyName, _hexEncode(key));
    return key;
  }

  Future<void> _restore(String raw) async {
    try {
      final envelope = jsonDecode(raw);
      final decoded = _isEncrypted(raw)
          ? jsonDecode(
              utf8.decode(
                await decryptBytes(
                  envelope as Map<String, dynamic>,
                  _databaseKey,
                  aad: utf8.encode(_storageKey),
                ),
              ),
            )
          : envelope;
      if (decoded is! Map<String, dynamic>) return;
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
    } on Object {
      _version = 0;
      for (final rows in _tables.values) rows.clear();
    }
  }

  bool _isEncrypted(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map && value['format'] == envelopeFormat;
    } on Object {
      return false;
    }
  }

  void _queuePersist() {
    _persistCompleter ??= Completer<void>();
    if (_persistScheduled) return;
    _persistScheduled = true;
    Timer.run(() async {
      _persistScheduled = false;
      final completer = _persistCompleter!;
      try {
        await _persistNow();
        if (_persistScheduled) return;
        _persistCompleter = null;
        completer.complete();
      } catch (error, stackTrace) {
        _persistCompleter = null;
        completer.completeError(error, stackTrace);
      }
    });
  }

  Future<void> _flushPersist() async {
    final pending = _persistCompleter;
    if (pending != null) await pending.future;
  }

  Future<void> _persistNow() async {
    final envelope = await encryptJson(
      {'version': _version, 'tables': _tables},
      _databaseKey,
      aad: utf8.encode(_storageKey),
    );
    await _preferences.setString(_storageKey, jsonEncode(envelope));
  }

  void _ensureReady(String table) {
    if (!_isOpen) throw StateError('Database is not open.');
    if (!_tables.containsKey(table))
      throw ArgumentError.value(table, 'table', 'Unknown table.');
  }

  String _hexEncode(List<int> bytes) =>
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();

  List<int> _hexDecode(String value) => [
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}

/// Local durable key storage. Production adapters can implement the same
/// [KeyStorage] contract on platforms with a hardware keystore.
class PersistentKeyStorage implements KeyStorage {
  const PersistentKeyStorage(this._storage);

  final FlutterSecureStorage _storage;

  static Future<PersistentKeyStorage> create() async =>
      const PersistentKeyStorage(FlutterSecureStorage());

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
