import 'dart:math';

import 'institution_key_manager.dart';
import '../../../features/projects/domain/services/project_key_service.dart';

class ProjectKeyManager implements ProjectKeyService {
  ProjectKeyManager(this._storage);

  final KeyStorage _storage;

  Future<bool> hasKey(String projectId) async => (await _storage.read(_keyName(projectId))) != null;

  Future<void> initialize(String projectId) async {
    if (await hasKey(projectId)) return;
    await _storage.write(_keyName(projectId), _generateKey());
  }

  Future<void> rotate(String projectId) async => _storage.write(_keyName(projectId), _generateKey());

  String _keyName(String projectId) => 'project.$projectId.key';

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
