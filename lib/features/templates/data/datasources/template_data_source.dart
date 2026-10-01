abstract interface class TemplateDataSource {
  Future<List<Map<String, Object?>>> getTemplates();
  Future<String?> selectedForProject(String projectId);
  Future<void> insertTemplate(Map<String, Object?> row);
  Future<void> updateTemplate(String id, Map<String, Object?> values);
  Future<void> selectForProject(String projectId, String templateId);
  Future<bool> isUsedByProject(String templateId);
  Future<void> deleteTemplate(String id);
}
