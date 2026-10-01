export 'verification_event.dart';
export 'verification_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'verification_event.dart';
import 'verification_state.dart';
import '../../domain/certificate_verification_service.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  VerificationBloc(this._service) : super(const VerificationState()) {
    on<VerifyCertificateFile>((event, emit) {
      return _verify(
        emit,
        () => _service.verifyFile(event.bytes, fileName: event.fileName),
      );
    });
    on<VerifyCertificateId>(
      (event, emit) => _verify(emit, () => _service.verify(event.id)),
    );
    on<VerifyQrPayload>(
      (event, emit) => _verify(emit, () => _service.verifyQr(event.payload)),
    );
  }

  final CertificateVerificationServiceContract _service;

  Future<void> _verify(
    Emitter<VerificationState> emit,
    Future<CertificateVerificationResult> Function() action,
  ) async {
    emit(const VerificationState(status: VerificationStatus.loading));
    try {
      emit(
        VerificationState(
          status: VerificationStatus.loaded,
          result: await action(),
        ),
      );
    } catch (error) {
      emit(
        VerificationState(
          status: VerificationStatus.failure,
          errorMessage: error,
        ),
      );
    }
  }
}
