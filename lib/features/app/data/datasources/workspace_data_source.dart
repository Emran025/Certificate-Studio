import '../../../../core/database/app_database.dart';

abstract interface class WorkspaceDataSource {
  Future<int> count(String table);
}

class WorkspaceDataSourceImpl implements WorkspaceDataSource {
  WorkspaceDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<int> count(String table) async => (await _database.query(table)).length;
}
