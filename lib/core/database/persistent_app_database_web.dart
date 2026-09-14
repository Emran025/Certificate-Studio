import 'app_database.dart';
import '../security/keys/institution_key_manager.dart';

/// Web currently has no file-backed SQLCipher runtime in this application.
/// Failing closed is safer than silently falling back to encrypted preferences.
class PersistentAppDatabase implements AppDatabase {
  PersistentAppDatabase._();

  static Future<PersistentAppDatabase> create({KeyStorage? keyStorage}) async =>
      throw UnsupportedError('SQLCipher persistence is not available on Flutter Web.');

  @override
  int get version => 0;
  @override
  bool get isOpen => false;
  @override
  Future<void> open() => _unsupported();
  @override
  Future<void> close() async {}
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    Map<String, Object?> where = const {},
    List<String>? columns,
  }) => _unsupported();
  @override
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values) => _unsupported();
  @override
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String conflictColumn = 'id',
  }) => _unsupported();
  @override
  Future<void> update(String table, String id, Map<String, Object?> values) => _unsupported();
  @override
  Future<void> delete(String table, String id) => _unsupported();
  @override
  Future<void> deleteWhere(String table, Map<String, Object?> where) => _unsupported();
  @override
  Future<void> deleteWhereIn(String table, String column, Iterable<Object?> values) => _unsupported();
  @override
  void beginBatch() => throw UnsupportedError('SQLCipher persistence is not available on Flutter Web.');
  @override
  Future<void> endBatch() async {}

  Future<T> _unsupported<T>() => Future.error(
        UnsupportedError('SQLCipher persistence is not available on Flutter Web.'),
      );
}

class PersistentKeyStorage implements KeyStorage {
  const PersistentKeyStorage._();
  static Future<PersistentKeyStorage> create() async => const PersistentKeyStorage._();
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}
