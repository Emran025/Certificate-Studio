class TemplateAsset {
  const TemplateAsset({
    required this.id,
    required this.name,
    required this.filePath,
    required this.width,
    required this.height,
    required this.dpi,
    required this.format,
  });

  final String id;
  final String name;
  final String filePath;
  final int width;
  final int height;
  final double dpi;
  final String format;
}
