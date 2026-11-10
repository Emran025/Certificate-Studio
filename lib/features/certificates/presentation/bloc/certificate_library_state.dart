import '../../domain/entities/certificate_record.dart';

enum CertificateLibraryStatus { initial, loading, loaded, failure }

class CertificateLibraryState {
  const CertificateLibraryState({
    this.status = CertificateLibraryStatus.initial,
    this.certificates = const [],
    this.phoneFields = const [],
    this.errorMessage,
  });
  final CertificateLibraryStatus status;
  final List<CertificateRecord> certificates;
  final List<String> phoneFields;
  final String? errorMessage;
}
