import 'export_file_writer_io.dart'
    if (dart.library.html) 'export_file_writer_web.dart' as platform;

Future<String?> saveExportBytes({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required List<int> bytes,
}) {
  return platform.saveExportBytes(
    dialogTitle: dialogTitle,
    fileName: fileName,
    extension: extension,
    bytes: bytes,
  );
}
