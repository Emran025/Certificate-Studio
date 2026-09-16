import '../entities/certificate_record.dart';
import '../repositories/certificate_repository.dart';

class GetCertificates {
  GetCertificates(this._repository);
  final CertificateRepository _repository;
  Future<List<CertificateRecord>> call({String? projectId}) =>
      _repository.getAll(projectId: projectId);
}
