import 'dart:typed_data';

import '../../domain/entities/share_target.dart';

abstract interface class CertificateShareDataSource {
  Future<bool> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  });
}
