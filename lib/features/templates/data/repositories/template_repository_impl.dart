import '../../domain/entities/template_asset.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/template_data_source.dart';
import '../models/template_asset_model.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  TemplateRepositoryImpl(this._dataSource);
  final TemplateDataSource _dataSource;
  @override
  Future<List<TemplateAsset>> getAll() async =>
      (await _dataSource.getTemplates())
          .map(TemplateAssetModel.fromRow)
          .toList(growable: false);
  @override
  Future<String?> selectedForProject(String projectId) =>
      _dataSource.selectedForProject(projectId);
  @override
  Future<TemplateAsset> add(TemplateAsset template) async {
    final model = TemplateAssetModel(
      id: template.id,
      name: template.name,
      filePath: template.filePath,
      width: template.width,
      height: template.height,
      dpi: template.dpi,
      format: template.format,
    );
    await _dataSource.insertTemplate(
      model.toRow(now: DateTime.now().toUtc().toIso8601String()),
    );
    return model;
  }
  @override
  Future<void> update(TemplateAsset template) => _dataSource.updateTemplate(
        template.id,
        {
          'name': template.name,
          'file_path': template.filePath,
          'width': template.width,
          'height': template.height,
          'dpi': template.dpi,
          'format': template.format,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
  @override
  Future<void> selectForProject(String projectId, String templateId) =>
      _dataSource.selectForProject(projectId, templateId);
  @override
  Future<bool> isUsedByProject(String templateId) =>
      _dataSource.isUsedByProject(templateId);
  @override
  Future<void> delete(String id) => _dataSource.deleteTemplate(id);
}
