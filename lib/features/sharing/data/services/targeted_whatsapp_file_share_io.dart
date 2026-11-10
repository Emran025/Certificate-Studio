import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/share_failure.dart';

const _channel = MethodChannel('com.example.certificate_studio/whatsapp_share');

Future<void> sharePdfToWhatsApp({
  required Uint8List bytes,
  required String fileName,
  required String packageName,
  String? phoneNumber,
}) async {
  if (!Platform.isAndroid) {
    throw const CertificateShareFailure(
      'Direct WhatsApp sharing is available on Android only.',
    );
  }

  final temporaryDirectory = await getTemporaryDirectory();
  final shareDirectory = Directory(
    '${temporaryDirectory.path}${Platform.pathSeparator}certificate_studio_shares',
  );
  await shareDirectory.create(recursive: true);
  await _removeStaleShareFiles(shareDirectory);
  final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$fileName';
  final file = File(
    '${shareDirectory.path}${Platform.pathSeparator}$uniqueName',
  );

  try {
    await file.writeAsBytes(bytes, flush: true);
    await _channel.invokeMethod<void>('sharePdfToWhatsApp', {
      'packageName': packageName,
      'phoneNumber': phoneNumber,
      'filePath': file.path,
    });
  } on PlatformException catch (error) {
    await _deleteShareFile(file);
    final message = error.code == 'APP_NOT_INSTALLED'
        ? 'WhatsApp is not installed.'
        : 'The PDF could not be shared.';
    throw CertificateShareFailure(message);
  } on MissingPluginException {
    await _deleteShareFile(file);
    throw const CertificateShareFailure(
      'Direct WhatsApp sharing is unavailable on this device.',
    );
  } catch (_) {
    await _deleteShareFile(file);
    rethrow;
  }
}

Future<void> _removeStaleShareFiles(Directory shareDirectory) async {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  try {
    await for (final entity in shareDirectory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.pdf')) {
        continue;
      }
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } on FileSystemException {
        // A stale cache entry should not prevent sharing a new certificate.
      }
    }
  } on FileSystemException {
    // Cache cleanup is best-effort; the operating system also manages cache files.
  }
}

Future<void> _deleteShareFile(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // The cache can be cleared by the system while a share is being prepared.
  }
}
