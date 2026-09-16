import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/certificate_verification_service.dart';

sealed class VerificationEvent {
  const VerificationEvent();
}

final class VerifyCertificateFile extends VerificationEvent {
  const VerifyCertificateFile(this.bytes, this.fileName);

  final Uint8List bytes;
  final String fileName;
}

final class VerifyCertificateId extends VerificationEvent {
  const VerifyCertificateId(this.id);

  final String id;
}

final class VerifyQrPayload extends VerificationEvent {
  const VerifyQrPayload(this.payload);

  final String payload;
}

enum VerificationStatus { idle, loading, loaded, failure }

class VerificationState {
  const VerificationState({
    this.status = VerificationStatus.idle,
    this.result,
    this.errorMessage,
  });

  final VerificationStatus status;
  final CertificateVerificationResult? result;
  final Object? errorMessage;
}

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

  final CertificateVerificationService _service;

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
