import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
      database.execute('PRAGMA foreign_keys = ON');
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
    List<String>? columns,
  }) async {
    _ensureReady(table);
    final clause = _whereClause(where);
    final projection = columns == null || columns.isEmpty
        ? '*'
        : columns.map(_quoteIdentifier).join(', ');
    final rows = _database.select(
      'SELECT $projection FROM ${_quoteIdentifier(table)}$clause',
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
    _run(
      () => _database.execute(
        'INSERT INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders)',
        values.values.map(_bindValue).toList(),
      ),
    );
    return Map<String, Object?>.from(values);
  }

  @override
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String conflictColumn = 'id',
  }) async {
    _ensureReady(table);
    if (values.isEmpty) throw ArgumentError.value(values, 'values');
    if (!values.containsKey(conflictColumn)) {
      throw ArgumentError('Missing conflict column "$conflictColumn".');
    }
    final columns = values.keys.map(_quoteIdentifier).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final updates = values.keys
        .where((key) => key != conflictColumn)
        .map(
          (key) =>
              '${_quoteIdentifier(key)} = excluded.${_quoteIdentifier(key)}',
        )
        .join(', ');
    final conflict = _quoteIdentifier(conflictColumn);
    final suffix = updates.isEmpty ? 'DO NOTHING' : 'DO UPDATE SET $updates';
    _run(
      () => _database.execute(
        'INSERT INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders) '
        'ON CONFLICT ($conflict) $suffix',
        values.values.map(_bindValue).toList(),
      ),
    );
    return Map<String, Object?>.from(values);
  }

  @override
  Future<void> update(
    String table,
    String id,
    Map<String, Object?> values,
  ) async {
    _ensureReady(table);
    if (values.isEmpty) return;
    final assignments = values.keys
        .map((key) => '${_quoteIdentifier(key)} = ?')
        .join(', ');
    _run(() {
      final primaryKey = _primaryKeyColumn(table);
      _database.execute(
        'UPDATE ${_quoteIdentifier(table)} SET $assignments WHERE ${_quoteIdentifier(primaryKey)} = ?',
        [...values.values.map(_bindValue), id],
      );
      if (_database.updatedRows == 0) {
        throw StateError('No record with id "$id" exists in $table.');
      }
    });
  }

  @override
  Future<void> delete(String table, String id) async {
    _ensureReady(table);
    _run(
      () => _database.execute(
        'DELETE FROM ${_quoteIdentifier(table)} WHERE ${_quoteIdentifier(_primaryKeyColumn(table))} = ?',
        [id],
      ),
    );
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object?> where) async {
    _ensureReady(table);
    final clause = _whereClause(where);
    _run(
      () => _database.execute(
        'DELETE FROM ${_quoteIdentifier(table)}$clause',
        where.values.map(_bindValue).toList(),
      ),
    );
  }

  @override
  Future<void> deleteWhereIn(
    String table,
    String column,
    Iterable<Object?> values,
  ) async {
    _ensureReady(table);
    final selected = values.map(_bindValue).toList(growable: false);
    if (selected.isEmpty) return;
    for (var offset = 0; offset < selected.length; offset += 500) {
      final chunk = selected.sublist(
        offset,
        math.min(offset + 500, selected.length),
      );
      final placeholders = List.filled(chunk.length, '?').join(', ');
      _run(
        () => _database.execute(
          'DELETE FROM ${_quoteIdentifier(table)} '
          'WHERE ${_quoteIdentifier(column)} IN ($placeholders)',
          chunk,
        ),
      );
    }
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
      if (current == 0) {
        for (final statement in DatabaseMigrations.statementsForUpgrade(0)) {
          _database.execute(statement);
        }
      } else {
        for (final migration in DatabaseMigrations.pendingFrom(current)) {
          if (migration.toVersion == 5) {
            _migrateRecordTerminologyIfNeeded();
          } else if (migration.toVersion == 6) {
            _migrateSignatureAssetsIfNeeded();
          } else if (migration.toVersion == 7) {
            _migrateCanonicalRelationships();
          } else if (migration.toVersion == 8) {
            _migrateDenormalizedProjectSettings();
          } else if (migration.toVersion == 9) {
            _migrateCertificateFieldFonts();
          } else {
            for (final statement in migration.statements) {
              _database.execute(statement);
            }
          }
        }
      }
      _database.execute('PRAGMA user_version = ${DatabaseSchema.version}');
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void _migrateRecordTerminologyIfNeeded() {
    // The terminology refactor shipped without a version bump. Some v4
    // databases already contain `records`, while older v4 files still
    // contain `students`. Detect the actual schema before renaming.
    if (!_hasTable('students')) return;
    _database.execute('ALTER TABLE students RENAME TO records');
    _database.execute(
      'ALTER TABLE certificates RENAME COLUMN student_id TO record_id',
    );
    _database.execute(
      'ALTER TABLE generation_items RENAME COLUMN student_id TO record_id',
    );
    _database.execute('DROP INDEX IF EXISTS idx_students_project');
    _database.execute('DROP INDEX IF EXISTS idx_generation_items_student');
    _database.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_project ON records (project_id)',
    );
    _database.execute(
      'CREATE INDEX IF NOT EXISTS idx_generation_items_record '
      'ON generation_items (record_id)',
    );
  }

  void _migrateSignatureAssetsIfNeeded() {
    // Keep this conditional for v4/v5 databases created after the terminology
    // refactor but before the visual-signature table was clarified.
    if (!_hasTable('signatures')) return;
    _database.execute('ALTER TABLE signatures RENAME TO signature_assets');
    _database.execute('DROP INDEX IF EXISTS idx_signatures_project');
    _database.execute(
      'CREATE INDEX IF NOT EXISTS idx_signature_assets_project '
      'ON signature_assets (project_id)',
    );
  }

  void _migrateCanonicalRelationships() {
    // Canonicalize institution_id as the internal institutions.id used by the
    // UI and domain. Older exported data may contain the public identifier;
    // the copy query resolves either representation without data loss.
    _database.execute('''
      CREATE TABLE projects_new (
        id TEXT PRIMARY KEY,
        institution_id TEXT NOT NULL,
        name TEXT NOT NULL,
        course_name TEXT,
        description TEXT,
        start_date TEXT,
        end_date TEXT,
        trainer_name TEXT,
        organization_name TEXT,
        logo_path TEXT,
        template_id TEXT,
        settings_json TEXT,
        project_key_reference TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (institution_id) REFERENCES institutions (id),
        FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE SET NULL
      )
    ''');
    _database.execute('''
      INSERT INTO projects_new
      SELECT p.id,
        COALESCE(
          (SELECT i.id FROM institutions i WHERE i.id = p.institution_id),
          (SELECT i.id FROM institutions i WHERE i.institution_id = p.institution_id)
        ),
        p.name, p.course_name, p.description, p.start_date, p.end_date,
        p.trainer_name, p.organization_name, p.logo_path, p.template_id,
        p.settings_json, p.project_key_reference, p.version,
        p.created_at, p.updated_at
      FROM projects p
    ''');
    _database.execute('DROP TABLE projects');
    _database.execute('ALTER TABLE projects_new RENAME TO projects');

    _database.execute('''
      CREATE TABLE generation_items_new (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        record_id TEXT NOT NULL,
        certificate_id TEXT,
        status TEXT NOT NULL,
        error_message TEXT,
        completed_at TEXT,
        FOREIGN KEY (job_id) REFERENCES generation_jobs (id),
        FOREIGN KEY (record_id) REFERENCES records (id),
        FOREIGN KEY (certificate_id) REFERENCES certificates (id)
      )
    ''');
    _database.execute(
      'INSERT INTO generation_items_new SELECT * FROM generation_items',
    );
    _database.execute('DROP TABLE generation_items');
    _database.execute(
      'ALTER TABLE generation_items_new RENAME TO generation_items',
    );

    final unsigned = _database.select(
      'SELECT id FROM verification_records WHERE signature IS NULL',
    );
    if (unsigned.isNotEmpty) {
      throw StateError(
        'Cannot migrate unsigned verification records: '
        '${unsigned.length} record(s) require review.',
      );
    }
    _database.execute('''
      CREATE TABLE verification_records_new (
        id TEXT PRIMARY KEY,
        certificate_id TEXT NOT NULL UNIQUE,
        institution_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        signature TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (certificate_id) REFERENCES certificates (id),
        FOREIGN KEY (institution_id) REFERENCES institutions (id),
        FOREIGN KEY (project_id) REFERENCES projects (id)
      )
    ''');
    _database.execute('''
      INSERT INTO verification_records_new
      SELECT v.id, v.certificate_id,
        COALESCE(
          (SELECT i.id FROM institutions i WHERE i.id = v.institution_id),
          (SELECT i.id FROM institutions i WHERE i.institution_id = v.institution_id)
        ),
        v.project_id, v.payload_json, v.signature, v.created_at
      FROM verification_records v
    ''');
    _database.execute('DROP TABLE verification_records');
    _database.execute(
      'ALTER TABLE verification_records_new RENAME TO verification_records',
    );
    _database.execute('DROP TABLE IF EXISTS signature_assets');

    for (final statement in DatabaseSchema.indexes) {
      _database.execute(
        statement.replaceAll('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
      );
    }
  }

  void _migrateDenormalizedProjectSettings() {
    final mappingRows = _database.select(
      'SELECT key, value_json FROM settings WHERE key LIKE ? ',
      ['mapping:%'],
    );
    for (final row in mappingRows) {
      final key = row['key']?.toString() ?? '';
      final projectId = key.startsWith('mapping:')
          ? key.substring('mapping:'.length)
          : '';
      if (projectId.isEmpty) continue;
      final projects = _database.select(
        'SELECT settings_json FROM projects WHERE id = ?',
        [projectId],
      );
      if (projects.isEmpty) continue;
      final settings = <String, dynamic>{};
      final rawSettings = projects.first['settings_json'];
      if (rawSettings is String && rawSettings.isNotEmpty) {
        final decoded = jsonDecode(rawSettings);
        if (decoded is Map) {
          settings.addAll(Map<String, dynamic>.from(decoded));
        }
      }
      final rawMapping = row['value_json'];
      if (rawMapping is String && rawMapping.isNotEmpty) {
        final mapping = jsonDecode(rawMapping);
        if (mapping is Map) settings['mapping'] = mapping;
      }
      _database.execute('UPDATE projects SET settings_json = ? WHERE id = ?', [
        jsonEncode(settings),
        projectId,
      ]);
    }
    _database.execute("DELETE FROM settings WHERE key LIKE 'mapping:%'");
    _database.execute('DROP TABLE IF EXISTS certificate_layouts');
    _database.execute('DROP TABLE IF EXISTS generation_items');
    _database.execute('DROP TABLE IF EXISTS generation_jobs');
  }

  void _migrateCertificateFieldFonts() {
    final fontRows = _database.select('SELECT id, family FROM fonts');
    final fontIdsByFamily = <String, String>{
      for (final row in fontRows)
        if (row['id'] != null && row['family'] != null)
          row['family'].toString(): row['id'].toString(),
    };
    final fields = _database.select(
      'SELECT id, project_id, class_name, source, position_json, style_json, '
      'created_at, updated_at FROM certificate_fields',
    );
    _database.execute('''CREATE TABLE certificate_fields_new (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      font_id TEXT,
      class_name TEXT NOT NULL,
      source TEXT,
      position_json TEXT NOT NULL,
      style_json TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id),
      FOREIGN KEY (font_id) REFERENCES fonts (id) ON DELETE SET NULL
    )''');
    for (final field in fields) {
      final style = field['style_json'] is String
          ? jsonDecode(field['style_json'] as String)
          : null;
      final family = style is Map ? style['font_family']?.toString() : null;
      final fontId = family == null ? null : fontIdsByFamily[family];
      _database.execute(
        'INSERT INTO certificate_fields_new '
        '(id, project_id, font_id, class_name, source, position_json, '
        'style_json, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          field['id'],
          field['project_id'],
          fontId,
          field['class_name'],
          field['source'],
          field['position_json'],
          field['style_json'],
          field['created_at'],
          field['updated_at'],
        ],
      );
    }
    _database.execute('DROP TABLE certificate_fields');
    _database.execute(
      'ALTER TABLE certificate_fields_new RENAME TO certificate_fields',
    );
    _database.execute(
      'CREATE INDEX IF NOT EXISTS idx_certificate_fields_project '
      'ON certificate_fields (project_id)',
    );
    _database.execute(
      'CREATE INDEX IF NOT EXISTS idx_certificate_fields_font '
      'ON certificate_fields (font_id)',
    );
  }

  bool _hasTable(String table) => _database.select(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [table],
  ).isNotEmpty;

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
          ? jsonDecode(
              utf8.decode(
                await decryptBytes(
                  Map<String, dynamic>.from(envelope),
                  key,
                  aad: utf8.encode(_legacyStorageKey),
                ),
              ),
            )
          : envelope;
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on Object {
      // The legacy preference may have been encrypted with a key that is no
      // longer available (for example, after secure-storage reset). Do not
      // block startup of the new SQLCipher database or delete the blob: a
      // later run may still have access to the original key.
      return null;
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

  static String _primaryKeyColumn(String table) =>
      table == DatabaseTables.settings ? 'key' : 'id';

  static String _whereClause(Map<String, Object?> where) => where.isEmpty
      ? ''
      : ' WHERE ${where.keys.map((key) => '${_quoteIdentifier(key)} = ?').join(' AND ')}';

  static String _quoteIdentifier(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';

  static Object? _bindValue(Object? value) =>
      value is bool ? (value ? 1 : 0) : value;

  static void _assertSqlCipher(Database database) {
    // `PRAGMA cipher` identifies SQLite3MultipleCiphers, not SQLCipher.
    // SQLCipher reports its compiled version through `cipher_version`.
    if (database.select('PRAGMA cipher_version').isEmpty) {
      throw StateError(
        'SQLCipher is not available in the bundled SQLite library.',
      );
    }
  }

  static void _setKey(Database database, List<int> key) {
    final hex = key
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
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
    await storage.write(
      _databaseKeyName,
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
    return key;
  }
}

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
