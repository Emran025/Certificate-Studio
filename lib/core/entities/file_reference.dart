class FileReference {
  const FileReference({required this.path, required this.fileName, required this.extension});

  final String path;
  final String fileName;
  final String extension;

  Map<String, Object?> toJson() => {
        'path': path,
        'fileName': fileName,
        'extension': extension,
      };

  factory FileReference.fromJson(Map<String, Object?> json) {
    return FileReference(
      path: json['path']! as String,
      fileName: json['fileName']! as String,
      extension: json['extension']! as String,
    );
  }
}
