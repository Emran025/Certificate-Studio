abstract interface class ProjectDataSource {
  Future<List<Map<String, Object?>>> getProjects({String? institutionId});
  Future<Map<String, Object?>?> getProject(String id);
  Future<void> saveProject(Map<String, Object?> row);
  Future<void> deleteProject(String id);
  Future<void> deleteProjectCascade(String id);
}
