import '../entities/template_asset.dart';

abstract interface class TemplateRepository {
  Future<List<TemplateAsset>> getAll();
  Future<String?> selectedForProject(String projectId);
  Future<TemplateAsset> add(TemplateAsset template);
  Future<void> update(TemplateAsset template);
  Future<void> selectForProject(String projectId, String templateId);
  Future<bool> isUsedByProject(String templateId);
  Future<void> delete(String id);
}
