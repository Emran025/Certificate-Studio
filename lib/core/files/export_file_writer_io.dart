import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<String?> saveExportBytes({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required List<int> bytes,
}) async {
  // Do not pass bytes to saveFile on native platforms. Some file_picker
  // versions return the selected path without writing the supplied bytes.
  final path = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
  );
  if (path == null || path.isEmpty) return null;

  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  if (!await file.exists() || await file.length() != bytes.length) {
    throw FileSystemException('The exported file was not written.', path);
  }
  return path;
}
