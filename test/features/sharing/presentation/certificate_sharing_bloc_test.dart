import 'package:certificate_studio/core/entities/operation_result.dart';
import 'package:certificate_studio/features/sharing/domain/entities/share_target.dart';
import 'package:certificate_studio/features/sharing/domain/repositories/certificate_sharing_repository.dart';
import 'package:certificate_studio/features/sharing/domain/usecases/share_certificate_pdf.dart';
import 'package:certificate_studio/features/sharing/presentation/bloc/certificate_sharing_bloc.dart';
import 'package:certificate_studio/features/sharing/presentation/bloc/certificate_sharing_event.dart';
import 'package:certificate_studio/features/sharing/presentation/bloc/certificate_sharing_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'success asks the user to verify recipient and PDF before sending',
    () async {
      final bloc = CertificateSharingBloc(
        ShareCertificatePdf(
          _FakeSharingRepository(const OperationSuccess<bool>(true)),
        ),
      );
      final stateFuture = bloc.stream.firstWhere(
        (state) => state.status == CertificateSharingStatus.success,
      );

      bloc.add(
        const CertificatePdfShareRequested(
          pdfReference: 'artifact://certificate.pdf',
          fileName: 'certificate.pdf',
          target: ShareTarget.whatsApp,
          phoneNumber: '967712345678',
        ),
      );

      final state = await stateFuture.timeout(const Duration(seconds: 2));
      expect(
        state.message,
        'WhatsApp share requested. Recipient routing is best-effort; verify the chat and PDF before sending.',
      );
      await bloc.close();
    },
  );

  test('repository failure is exposed by the sharing BLoC', () async {
    final bloc = CertificateSharingBloc(
      ShareCertificatePdf(
        _FakeSharingRepository(
          const OperationFailure<bool>('Sharing was cancelled.'),
        ),
      ),
    );
    final stateFuture = bloc.stream.firstWhere(
      (state) => state.status == CertificateSharingStatus.failure,
    );

    bloc.add(
      const CertificatePdfShareRequested(
        pdfReference: 'artifact://certificate.pdf',
        fileName: 'certificate.pdf',
        target: ShareTarget.system,
      ),
    );

    final state = await stateFuture.timeout(const Duration(seconds: 2));
    expect(state.message, 'Sharing was cancelled.');
    await bloc.close();
  });
}

class _FakeSharingRepository implements CertificateSharingRepository {
  const _FakeSharingRepository(this.result);

  final OperationResult<bool> result;

  @override
  Future<OperationResult<bool>> sharePdf({
    required String pdfReference,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  }) async => result;
}
