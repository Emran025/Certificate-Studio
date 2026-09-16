import '../../../../core/security/keys/institution_key_manager.dart';
import '../repositories/project_repository.dart';

class DeleteProject {
  DeleteProject(this._repository, this._keyStorage);

  final ProjectRepository _repository;
  final KeyStorage _keyStorage;

  Future<void> call(String projectId) async {
    await _repository.deleteCascade(projectId);
    await _keyStorage.delete('project.$projectId.key');
  }
}
