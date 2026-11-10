export 'certificate_library_event.dart';
export 'certificate_library_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'certificate_library_event.dart';
import 'certificate_library_state.dart';
import '../../domain/usecases/get_certificates.dart';
import '../../../data_import/domain/entities/field_rule.dart';
import '../../../data_import/domain/usecases/get_imported_table.dart';

class CertificateLibraryBloc
    extends Bloc<CertificateLibraryEvent, CertificateLibraryState> {
  CertificateLibraryBloc(
    this._getCertificates,
    this._projectId, {
    GetImportedTable? getImportedTable,
  }) : _getImportedTable = getImportedTable,
       super(const CertificateLibraryState()) {
    on<CertificatesRequested>(_load);
  }
  final GetCertificates _getCertificates;
  final String? _projectId;
  final GetImportedTable? _getImportedTable;
  Future<void> _load(
    CertificatesRequested event,
    Emitter<CertificateLibraryState> emit,
  ) async {
    emit(
      CertificateLibraryState(
        status: CertificateLibraryStatus.loading,
        certificates: state.certificates,
        phoneFields: state.phoneFields,
      ),
    );
    try {
      final certificates = await _getCertificates(projectId: _projectId);
      final phoneFields = await _loadPhoneFields();
      emit(
        CertificateLibraryState(
          status: CertificateLibraryStatus.loaded,
          certificates: certificates,
          phoneFields: phoneFields,
        ),
      );
    } catch (error) {
      emit(
        CertificateLibraryState(
          status: CertificateLibraryStatus.failure,
          certificates: state.certificates,
          phoneFields: state.phoneFields,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<List<String>> _loadPhoneFields() async {
    final projectId = _projectId;
    final getImportedTable = _getImportedTable;
    if (projectId == null || getImportedTable == null) return state.phoneFields;
    final result = await getImportedTable(projectId);
    return result.fold<List<String>>(
      success: (table) => [
        for (final column in table.columns)
          if (table.fieldRules[column]?.kind == FieldRuleKind.phone ||
              _looksLikePhoneColumn(column))
            column,
      ],
      failure: (_) => state.phoneFields,
    );
  }

  bool _looksLikePhoneColumn(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    );
    return normalized.contains('phone') ||
        normalized.contains('mobile') ||
        normalized.contains('telephone') ||
        normalized == 'tel' ||
        normalized.contains('whatsapp') ||
        normalized.contains('هاتف') ||
        normalized.contains('جوال') ||
        normalized.contains('موبايل') ||
        normalized.contains('تلفون') ||
        normalized.contains('واتساب');
  }
}
