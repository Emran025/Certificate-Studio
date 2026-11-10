enum CertificateSharingStatus { idle, sharing, success, failure }

class CertificateSharingState {
  const CertificateSharingState({
    this.status = CertificateSharingStatus.idle,
    this.message,
  });

  final CertificateSharingStatus status;
  final String? message;
}
