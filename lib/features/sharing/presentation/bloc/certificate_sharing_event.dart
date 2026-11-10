import '../../domain/entities/share_target.dart';

sealed class CertificateSharingEvent {
  const CertificateSharingEvent();
}

final class CertificatePdfShareRequested extends CertificateSharingEvent {
  const CertificatePdfShareRequested({
    required this.pdfReference,
    required this.fileName,
    required this.target,
    this.phoneNumber,
  });

  final String pdfReference;
  final String fileName;
  final ShareTarget target;
  final String? phoneNumber;
}

final class ShareFeedbackCleared extends CertificateSharingEvent {
  const ShareFeedbackCleared();
}
