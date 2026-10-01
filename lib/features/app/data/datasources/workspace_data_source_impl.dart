import '../../../../core/database/app_database.dart';
import 'workspace_data_source.dart';

class WorkspaceDataSourceImpl implements WorkspaceDataSource {
  WorkspaceDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<int> count(String table) async => (await _database.query(table)).length;
}
