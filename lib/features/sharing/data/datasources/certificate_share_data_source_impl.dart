import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../../domain/entities/share_target.dart';
import '../../domain/entities/share_failure.dart';
import 'certificate_share_data_source.dart';
import '../services/targeted_whatsapp_file_share.dart';

class CertificateShareDataSourceImpl implements CertificateShareDataSource {
  @override
  Future<bool> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  }) async {
    switch (target) {
      case ShareTarget.system:
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(bytes),
                mimeType: 'application/pdf',
              ),
            ],
            fileNameOverrides: [fileName],
          ),
        );
        // `unavailable` means the platform cannot report the chosen target;
        // only an explicit dismissal indicates that the share sheet was canceled.
        return result.status != ShareResultStatus.dismissed;
      case ShareTarget.whatsApp:
        await _shareWhatsApp(
          bytes: bytes,
          fileName: fileName,
          packageName: 'com.whatsapp',
          phoneNumber: phoneNumber,
        );
        return true;
      case ShareTarget.whatsAppBusiness:
        await _shareWhatsApp(
          bytes: bytes,
          fileName: fileName,
          packageName: 'com.whatsapp.w4b',
          phoneNumber: phoneNumber,
        );
        return true;
    }
  }

  Future<void> _shareWhatsApp({
    required Uint8List bytes,
    required String fileName,
    required String packageName,
    String? phoneNumber,
  }) async {
    try {
      await sharePdfToWhatsApp(
        bytes: bytes,
        fileName: fileName,
        packageName: packageName,
        phoneNumber: phoneNumber,
      );
    } on CertificateShareFailure {
      rethrow;
    } catch (_) {
      throw const CertificateShareFailure('The PDF could not be shared.');
    }
  }
}
