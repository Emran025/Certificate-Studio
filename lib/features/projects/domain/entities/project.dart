import '../../../../core/entities/base_entity.dart';

class Project implements BaseEntity {
  const Project({
    required this.id,
    required this.institutionId,
    required this.name,
    this.courseName,
    this.description,
    this.startDate,
    this.endDate,
    this.trainerName,
    this.organizationName,
    this.logoPath,
    this.templateId,
    this.settings = const {},
    required this.projectKeyReference,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  final String institutionId;
  final String name;
  final String? courseName;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? trainerName;
  final String? organizationName;
  final String? logoPath;
  final String? templateId;
  final Map<String, Object?> settings;
  final String projectKeyReference;
  final int version;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
}
