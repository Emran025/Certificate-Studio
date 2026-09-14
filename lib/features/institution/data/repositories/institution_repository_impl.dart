import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/institution.dart';
import '../../domain/repositories/institution_repository.dart';
import '../models/institution_model.dart';

class InstitutionRepositoryImpl implements InstitutionRepository {
  InstitutionRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<Institution?> getCurrent() async {
    final rows = await _database.query(DatabaseTables.institutions);
    return rows.isEmpty ? null : InstitutionModel.fromRow(rows.first);
  }

  @override
  Future<Institution> save(Institution institution) async {
    final model = InstitutionModel(
      id: institution.id,
      institutionId: institution.institutionId,
      name: institution.name,
      nameAr: institution.nameAr,
      nameEn: institution.nameEn,
      logoPath: institution.logoPath,
      contact: institution.contact,
      settings: institution.settings,
      createdAt: institution.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    await _database.upsert(DatabaseTables.institutions, model.toRow());
    return model;
  }

  @override
  Future<void> delete(String id) => _database.delete(DatabaseTables.institutions, id);
}
