abstract interface class WorkspaceDataSource {
  Future<int> count(String table);
}
