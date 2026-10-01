export 'certificate_library_event.dart';
export 'certificate_library_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'certificate_library_event.dart';
import 'certificate_library_state.dart';
import '../../domain/usecases/get_certificates.dart';

class CertificateLibraryBloc
    extends Bloc<CertificateLibraryEvent, CertificateLibraryState> {
  CertificateLibraryBloc(this._getCertificates, this._projectId)
    : super(const CertificateLibraryState()) {
    on<CertificatesRequested>(_load);
  }
  final GetCertificates _getCertificates;
  final String? _projectId;
  Future<void> _load(
    CertificatesRequested event,
    Emitter<CertificateLibraryState> emit,
  ) async {
    emit(
      CertificateLibraryState(
        status: CertificateLibraryStatus.loading,
        certificates: state.certificates,
      ),
    );
    try {
      emit(
        CertificateLibraryState(
          status: CertificateLibraryStatus.loaded,
          certificates: await _getCertificates(projectId: _projectId),
        ),
      );
    } catch (error) {
      emit(
        CertificateLibraryState(
          status: CertificateLibraryStatus.failure,
          certificates: state.certificates,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
