import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/certificate_record.dart';
import '../../domain/usecases/get_certificates.dart';

sealed class CertificateLibraryEvent { const CertificateLibraryEvent(); }
final class CertificatesRequested extends CertificateLibraryEvent { const CertificatesRequested(); }

enum CertificateLibraryStatus { initial, loading, loaded, failure }

class CertificateLibraryState {
  const CertificateLibraryState({
    this.status = CertificateLibraryStatus.initial,
    this.certificates = const [],
    this.errorMessage,
  });
  final CertificateLibraryStatus status;
  final List<CertificateRecord> certificates;
  final String? errorMessage;
}

class CertificateLibraryBloc extends Bloc<CertificateLibraryEvent, CertificateLibraryState> {
  CertificateLibraryBloc(this._getCertificates, this._projectId)
      : super(const CertificateLibraryState()) {
    on<CertificatesRequested>(_load);
  }
  final GetCertificates _getCertificates;
  final String? _projectId;
  Future<void> _load(CertificatesRequested event, Emitter<CertificateLibraryState> emit) async {
    emit(CertificateLibraryState(status: CertificateLibraryStatus.loading, certificates: state.certificates));
    try {
      emit(CertificateLibraryState(
        status: CertificateLibraryStatus.loaded,
        certificates: await _getCertificates(projectId: _projectId),
      ));
    } catch (error) {
      emit(CertificateLibraryState(
        status: CertificateLibraryStatus.failure,
        certificates: state.certificates,
        errorMessage: error.toString(),
      ));
    }
  }
}
