import '../entities/font_asset.dart';

abstract interface class FontRepository {
  Future<List<FontAsset>> getAll();
  Future<String?> selectedForProject(String projectId);
  Future<FontAsset> add(FontAsset font, List<int> bytes);
  Future<void> selectForProject(String projectId, String fontId);
  Future<void> delete(String id);
}
