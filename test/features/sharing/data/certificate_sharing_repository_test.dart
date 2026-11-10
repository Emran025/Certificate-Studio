import 'dart:typed_data';

import 'package:certificate_studio/core/entities/operation_result.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/features/sharing/data/datasources/certificate_share_data_source.dart';
import 'package:certificate_studio/features/sharing/data/repositories/certificate_sharing_repository_impl.dart';
import 'package:certificate_studio/features/sharing/domain/entities/share_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shares the stored PDF to WhatsApp with a normalized recipient',
    () async {
      final store = InMemoryCertificateArtifactStore();
      final reference = await store.save(
        certificateId: 'certificate-1',
        extension: 'pdf',
        bytes: [37, 80, 68, 70],
      );
      final dataSource = _CapturingShareDataSource();
      final repository = CertificateSharingRepositoryImpl(
        artifactStore: store,
        dataSource: dataSource,
      );

      final result = await repository.sharePdf(
        pdfReference: reference,
        fileName: 'Student Certificate',
        target: ShareTarget.whatsApp,
        phoneNumber: '+967 712 345 678',
      );

      expect(result, isA<OperationSuccess<bool>>());
      expect(dataSource.calls, 1);
      expect(dataSource.bytes, [37, 80, 68, 70]);
      expect(dataSource.fileName, 'Student_Certificate.pdf');
      expect(dataSource.target, ShareTarget.whatsApp);
      expect(dataSource.phoneNumber, '967712345678');
    },
  );

  test('refuses direct sharing when the phone number is local', () async {
    final store = InMemoryCertificateArtifactStore();
    final reference = await store.save(
      certificateId: 'certificate-2',
      extension: 'pdf',
      bytes: [1, 2, 3],
    );
    final dataSource = _CapturingShareDataSource();
    final repository = CertificateSharingRepositoryImpl(
      artifactStore: store,
      dataSource: dataSource,
    );

    final result = await repository.sharePdf(
      pdfReference: reference,
      fileName: 'Local number',
      target: ShareTarget.whatsAppBusiness,
      phoneNumber: '712345678',
    );

    expect(result, isA<OperationFailure<bool>>());
    expect(dataSource.calls, 0);
  });

  test('returns a failure when the PDF artifact is missing', () async {
    final dataSource = _CapturingShareDataSource();
    final repository = CertificateSharingRepositoryImpl(
      artifactStore: InMemoryCertificateArtifactStore(),
      dataSource: dataSource,
    );

    final result = await repository.sharePdf(
      pdfReference: 'artifact://missing.pdf',
      fileName: 'Missing',
      target: ShareTarget.system,
    );

    expect(result, isA<OperationFailure<bool>>());
    expect(dataSource.calls, 0);
  });

  test(
    'returns a failure when the user dismisses the system share sheet',
    () async {
      final store = InMemoryCertificateArtifactStore();
      final reference = await store.save(
        certificateId: 'certificate-3',
        extension: 'pdf',
        bytes: [1, 2, 3],
      );
      final dataSource = _CapturingShareDataSource(shareAccepted: false);
      final repository = CertificateSharingRepositoryImpl(
        artifactStore: store,
        dataSource: dataSource,
      );

      final result = await repository.sharePdf(
        pdfReference: reference,
        fileName: 'Cancelled share',
        target: ShareTarget.system,
      );

      expect(result, isA<OperationFailure<bool>>());
    },
  );
}

class _CapturingShareDataSource implements CertificateShareDataSource {
  _CapturingShareDataSource({this.shareAccepted = true});

  final bool shareAccepted;
  int calls = 0;
  Uint8List? bytes;
  String? fileName;
  ShareTarget? target;
  String? phoneNumber;

  @override
  Future<bool> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  }) async {
    calls++;
    this.bytes = bytes;
    this.fileName = fileName;
    this.target = target;
    this.phoneNumber = phoneNumber;
    return shareAccepted;
  }
}
