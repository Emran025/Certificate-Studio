import 'dart:math';

abstract interface class KeyStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

/// Temporary adapter for the current bootstrap. Platform implementations should
/// use Android Keystore, iOS Keychain, desktop secure storage, or Web Crypto.
class InMemoryKeyStorage implements KeyStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class InstitutionKeyManager {
  InstitutionKeyManager(this._storage);

  static const _storageKey = 'institution.master_key';
  final KeyStorage _storage;

  Future<bool> hasKey() async => (await _storage.read(_storageKey)) != null;

  Future<void> initialize() async {
    if (await hasKey()) return;
    await _storage.write(_storageKey, _generateKey());
  }

  Future<void> rotate() async => _storage.write(_storageKey, _generateKey());

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
