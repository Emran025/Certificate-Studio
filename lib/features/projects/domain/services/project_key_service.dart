abstract interface class ProjectKeyService {
  Future<bool> hasKey(String projectId);
  Future<void> initialize(String projectId);
  Future<void> rotate(String projectId);
}
