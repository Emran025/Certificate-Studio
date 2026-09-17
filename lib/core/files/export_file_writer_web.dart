import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String?> saveExportBytes({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required List<int> bytes,
}) async {
  // On web, FilePicker owns the browser download and must receive a typed byte list.
  final uri = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: Uint8List.fromList(bytes),
  );
  return uri?.toString();
}
