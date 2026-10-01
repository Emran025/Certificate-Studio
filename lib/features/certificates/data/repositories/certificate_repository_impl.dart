import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/certificate_record.dart';
import '../models/certificate_record_model.dart';
import '../../domain/repositories/certificate_repository.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<List<CertificateRecord>> getAll({String? projectId}) async {
    final rows = await _database.query(
      DatabaseTables.certificates,
      where: projectId == null ? const {} : {'project_id': projectId},
    );
    final records = <CertificateRecord>[];
    for (final row in rows.reversed) {
      final recordS = await _database.query(
        DatabaseTables.records,
        where: {'id': row['record_id']},
      );
      records.add(
        CertificateRecordModel.fromRows(row, recordS.isEmpty ? null : recordS.first),
      );
    }
    return records;
  }
}
