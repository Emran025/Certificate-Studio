import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/verification/domain/certificate_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAppDatabase database;
  late InMemoryKeyStorage storage;
  late CertificateVerificationService service;

  setUp(() async {
    database = InMemoryAppDatabase();
    await database.open();
    storage = InMemoryKeyStorage();
    service = CertificateVerificationService(database, storage);
  });

  test(
    'returns unknown certificate for an id absent from the workspace',
    () async {
      final result = await service.verify('missing-certificate');

      expect(result.status, CertificateVerificationStatus.unknownCertificate);
      expect(result.certificateId, 'missing-certificate');
      expect(result.isValid, isFalse);
      expect(result.reason, contains('not found'));
    },
  );

  test('rejects malformed QR payload as unsupported', () async {
    final result = await service.verifyQr('not-a-certificate-payload');

    expect(result.status, CertificateVerificationStatus.unsupported);
    expect(result.qrExtracted, isFalse);
    expect(result.reason, isNotEmpty);
  });

  test('reports missing embedded data for a plain file', () async {
    final result = await service.verifyFile([
      1,
      2,
      3,
      4,
    ], fileName: 'certificate.pdf');

    expect(
      result.status,
      CertificateVerificationStatus.verificationDataMissing,
    );
    expect(result.isValid, isFalse);
  });

  test(
    'reports unsupported malformed image when no QR or record exists',
    () async {
      final result = await service.verifyFile([
        1,
        2,
        3,
        4,
      ], fileName: 'certificate.png');

      expect(
        result.status,
        CertificateVerificationStatus.verificationDataMissing,
      );
      expect(result.reason, contains('QR'));
    },
  );
}
