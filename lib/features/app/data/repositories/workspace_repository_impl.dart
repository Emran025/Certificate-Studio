import '../../domain/entities/workspace_metrics.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_data_source.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._dataSource);
  final WorkspaceDataSource _dataSource;
  @override
  Future<WorkspaceMetrics> getMetrics() async {
    final results = await Future.wait([
      _dataSource.count('templates'),
      _dataSource.count('fonts'),
      _dataSource.count('certificates'),
    ]);
    return WorkspaceMetrics(
      templates: results[0],
      fonts: results[1],
      certificates: results[2],
    );
  }
}
