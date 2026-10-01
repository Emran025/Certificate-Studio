import '../../domain/entities/certificate_record.dart';
import '../../domain/repositories/certificate_repository.dart';
import '../datasources/certificate_data_source.dart';
import '../models/certificate_record_model.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl(this._dataSource);
  final CertificateDataSource _dataSource;
  @override
  Future<List<CertificateRecord>> getAll({String? projectId}) async {
    final rows = await _dataSource.getCertificateRows(projectId: projectId);
    final records = <CertificateRecord>[];
    for (final row in rows.reversed) {
      final record = await _dataSource.getRecord(row['record_id']?.toString() ?? '');
      records.add(CertificateRecordModel.fromRows(row, record));
    }
    return records;
  }
}
