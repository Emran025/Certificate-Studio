import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import 'institution_data_source.dart';

class InstitutionDataSourceImpl implements InstitutionDataSource {
  InstitutionDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<List<Map<String, Object?>>> getCurrentRows() => _database.query(DatabaseTables.institutions);
  @override
  Future<void> save(Map<String, Object?> row) => _database.upsert(DatabaseTables.institutions, row);
  @override
  Future<void> delete(String id) => _database.delete(DatabaseTables.institutions, id);
}
