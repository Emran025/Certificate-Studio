import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/share_target.dart';
import '../../domain/usecases/share_certificate_pdf.dart';
import 'certificate_sharing_event.dart';
import 'certificate_sharing_state.dart';

class CertificateSharingBloc
    extends Bloc<CertificateSharingEvent, CertificateSharingState> {
  CertificateSharingBloc(this._shareCertificatePdf)
    : super(const CertificateSharingState()) {
    on<CertificatePdfShareRequested>(_sharePdf);
    on<ShareFeedbackCleared>(
      (event, emit) => emit(const CertificateSharingState()),
    );
  }

  final ShareCertificatePdf _shareCertificatePdf;

  Future<void> _sharePdf(
    CertificatePdfShareRequested event,
    Emitter<CertificateSharingState> emit,
  ) async {
    emit(
      const CertificateSharingState(status: CertificateSharingStatus.sharing),
    );
    try {
      final result = await _shareCertificatePdf(
        pdfReference: event.pdfReference,
        fileName: event.fileName,
        target: event.target,
        phoneNumber: event.phoneNumber,
      );
      result.fold<void>(
        success: (_) => emit(
          CertificateSharingState(
            status: CertificateSharingStatus.success,
            message: event.target == ShareTarget.system
                ? null
                : 'WhatsApp share requested. Recipient routing is best-effort; verify the chat and PDF before sending.',
          ),
        ),
        failure: (message) => emit(
          CertificateSharingState(
            status: CertificateSharingStatus.failure,
            message: message,
          ),
        ),
      );
    } catch (_) {
      emit(
        const CertificateSharingState(
          status: CertificateSharingStatus.failure,
          message: 'The PDF could not be shared.',
        ),
      );
    }
  }
}
