import '../../domain/entities/font_asset.dart';
import '../../domain/repositories/font_repository.dart';
import '../datasources/font_data_source.dart';
import '../models/font_asset_model.dart';

class FontRepositoryImpl implements FontRepository {
  FontRepositoryImpl(this._dataSource);
  final FontDataSource _dataSource;
  @override
  Future<List<FontAsset>> getAll() async =>
      (await _dataSource.getFonts())
          .map(FontAssetModel.fromRow)
          .toList(growable: false);
  @override
  Future<String?> selectedForProject(String projectId) =>
      _dataSource.selectedForProject(projectId);
  @override
  Future<FontAsset> add(FontAsset font, List<int> bytes) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final model = FontAssetModel(
      id: font.id,
      name: font.name,
      family: font.family,
      filePath: font.filePath,
      format: font.format,
    );
    await _dataSource.insertFont(model.toRow(bytes: bytes, now: now));
    return font;
  }
  @override
  Future<void> selectForProject(String projectId, String fontId) =>
      _dataSource.selectForProject(projectId, fontId);
  @override
  Future<void> delete(String id) => _dataSource.deleteFont(id);
}
