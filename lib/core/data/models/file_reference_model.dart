import '../../entities/file_reference.dart';

class FileReferenceModel extends FileReference {
  const FileReferenceModel({
    required super.path,
    required super.fileName,
    required super.extension,
  });

  factory FileReferenceModel.fromJson(Map<String, Object?> json) => FileReferenceModel(
        path: json['path']! as String,
        fileName: json['fileName']! as String,
        extension: json['extension']! as String,
      );

  Map<String, Object?> toJson() => {
        'path': path,
        'fileName': fileName,
        'extension': extension,
      };
}
