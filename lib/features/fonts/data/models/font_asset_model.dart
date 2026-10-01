import '../../domain/entities/font_asset.dart';

class FontAssetModel extends FontAsset {
  const FontAssetModel({
    required super.id,
    required super.name,
    required super.family,
    required super.filePath,
    required super.format,
  });

  factory FontAssetModel.fromRow(Map<String, Object?> row) => FontAssetModel(
        id: row['id']! as String,
        name: row['name']! as String,
        family: row['family']! as String,
        filePath: row['file_path']! as String,
        format: row['format']! as String,
      );

  Map<String, Object?> toRow({required List<int> bytes, required String now}) => {
        'id': id,
        'name': name,
        'family': family,
        'file_path': filePath,
        'format': format,
        'font_bytes': bytes,
        'created_at': now,
        'updated_at': now,
      };
}
