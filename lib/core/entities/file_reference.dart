class FileReference {
  const FileReference({
    required this.path,
    required this.fileName,
    required this.extension,
  });

  final String path;
  final String fileName;
  final String extension;
}
