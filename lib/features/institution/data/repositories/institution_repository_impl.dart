import '../../domain/entities/institution.dart';
import '../../domain/repositories/institution_repository.dart';
import '../datasources/institution_data_source.dart';
import '../models/institution_model.dart';

class InstitutionRepositoryImpl implements InstitutionRepository {
  InstitutionRepositoryImpl(this._dataSource);
  final InstitutionDataSource _dataSource;
  @override
  Future<Institution?> getCurrent() async {
    final rows = await _dataSource.getCurrentRows();
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
    await _dataSource.save(model.toRow());
    return model;
  }
  @override
  Future<void> delete(String id) => _dataSource.delete(id);
}
