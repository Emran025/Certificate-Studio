import '../entities/certificate_record.dart';

abstract interface class CertificateRepository {
  Future<List<CertificateRecord>> getAll({String? projectId});
}
