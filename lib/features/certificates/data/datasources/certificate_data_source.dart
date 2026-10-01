abstract interface class CertificateDataSource {
  Future<List<Map<String, Object?>>> getCertificateRows({String? projectId});
  Future<Map<String, Object?>?> getRecord(String id);
}
