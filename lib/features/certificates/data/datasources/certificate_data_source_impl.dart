import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import 'certificate_data_source.dart';

class CertificateDataSourceImpl implements CertificateDataSource {
  CertificateDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<List<Map<String, Object?>>> getCertificateRows({String? projectId}) =>
      _database.query(
        DatabaseTables.certificates,
        where: projectId == null ? const {} : {'project_id': projectId},
      );
  @override
  Future<Map<String, Object?>?> getRecord(String id) async {
    final rows = await _database.query(
      DatabaseTables.records,
      where: {'id': id},
    );
    return rows.isEmpty ? null : rows.first;
  }
}
