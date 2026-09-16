import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/workspace_metrics.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<WorkspaceMetrics> getMetrics() async {
    final results = await Future.wait([
      _database.query(DatabaseTables.templates),
      _database.query(DatabaseTables.fonts),
      _database.query(DatabaseTables.certificates),
    ]);

    return WorkspaceMetrics(
      templates: results[0].length,
      fonts: results[1].length,
      certificates: results[2].length,
    );
  }
}
