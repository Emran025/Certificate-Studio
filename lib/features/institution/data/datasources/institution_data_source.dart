abstract interface class InstitutionDataSource {
  Future<List<Map<String, Object?>>> getCurrentRows();
  Future<void> save(Map<String, Object?> row);
  Future<void> delete(String id);
}
