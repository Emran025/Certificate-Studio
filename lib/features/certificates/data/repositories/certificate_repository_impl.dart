import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/certificate_record.dart';
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
      final students = await _database.query(
        DatabaseTables.students,
        where: {'id': row['student_id']},
      );
      records.add(CertificateRecord(row, students.isEmpty ? null : students.first));
    }
    return records;
  }
}
