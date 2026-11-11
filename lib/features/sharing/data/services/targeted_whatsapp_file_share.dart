import 'dart:typed_data';

import 'targeted_whatsapp_file_share_stub.dart'
    if (dart.library.io) 'targeted_whatsapp_file_share_io.dart'
    as platform;

Future<void> sharePdfToWhatsApp({
  required Uint8List bytes,
  required String fileName,
  required String packageName,
  String? phoneNumber,
}) => platform.sharePdfToWhatsApp(
  bytes: bytes,
  fileName: fileName,
  packageName: packageName,
  phoneNumber: phoneNumber,
);
