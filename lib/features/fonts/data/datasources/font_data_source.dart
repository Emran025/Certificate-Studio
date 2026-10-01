abstract interface class FontDataSource {
  Future<List<Map<String, Object?>>> getFonts();
  Future<String?> selectedForProject(String projectId);
  Future<void> insertFont(Map<String, Object?> row);
  Future<void> selectForProject(String projectId, String fontId);
  Future<void> deleteFont(String id);
}
