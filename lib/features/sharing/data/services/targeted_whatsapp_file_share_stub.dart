import 'dart:typed_data';

import '../../domain/entities/share_failure.dart';

Future<void> sharePdfToWhatsApp({
  required Uint8List bytes,
  required String fileName,
  required String packageName,
  String? phoneNumber,
}) async {
  throw const CertificateShareFailure(
    'Direct WhatsApp sharing is available on Android only.',
  );
}
