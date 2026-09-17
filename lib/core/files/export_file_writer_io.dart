import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String?> saveExportBytes({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required List<int> bytes,
}) async {
  final uri = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: Uint8List.fromList(bytes),
  );
  if (uri == null) return null;
  if (uri.scheme != 'file') return uri.toString();

  final path = uri.toFilePath();
  final file = File(path);
  if (!await file.exists() || await file.length() != bytes.length) {
    throw FileSystemException('The exported file was not written.', path);
  }
  return path;
}
