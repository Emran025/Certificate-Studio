part of '../certificate_generation_screen.dart';

class CertificateGenerationScreen extends StatefulWidget {
  const CertificateGenerationScreen({
    super.key,
    required this.database,
    required this.keyStorage,
    required this.projectId,
    required this.projectName,
    required this.institutionId,
  });
  final AppDatabase database;
  final KeyStorage keyStorage;
  final String projectId;
  final String projectName;
  final String institutionId;
  @override
  State<CertificateGenerationScreen> createState() =>
      _CertificateGenerationScreenState();
}
