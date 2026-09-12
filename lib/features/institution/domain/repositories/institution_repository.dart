import '../entities/institution.dart';

abstract interface class InstitutionRepository {
  Future<Institution?> getCurrent();
  Future<Institution> save(Institution institution);
  Future<void> delete(String id);
}
