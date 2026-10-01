import '../../domain/entities/template_asset.dart';

class TemplateAssetModel extends TemplateAsset {
  const TemplateAssetModel({
    required super.id,
    required super.name,
    required super.filePath,
    required super.width,
    required super.height,
    required super.dpi,
    required super.format,
  });

  factory TemplateAssetModel.fromRow(Map<String, Object?> row) => TemplateAssetModel(
        id: row['id']! as String,
        name: row['name']! as String,
        filePath: row['file_path']! as String,
        width: row['width']! as int,
        height: row['height']! as int,
        dpi: (row['dpi']! as num).toDouble(),
        format: row['format']! as String,
      );

  Map<String, Object?> toRow({required String now}) => {
        'id': id,
        'name': name,
        'file_path': filePath,
        'width': width,
        'height': height,
        'dpi': dpi,
        'format': format,
        'created_at': now,
        'updated_at': now,
      };
}
