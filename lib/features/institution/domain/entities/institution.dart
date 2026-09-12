import '../../../../core/entities/base_entity.dart';

class Institution implements BaseEntity {
  const Institution({
    required this.id,
    required this.institutionId,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.logoPath,
    this.contact = const {},
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  final String institutionId;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? logoPath;
  final Map<String, Object?> contact;
  final Map<String, Object?> settings;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
}
