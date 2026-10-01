import '../../domain/certificate_verification_service.dart';

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
