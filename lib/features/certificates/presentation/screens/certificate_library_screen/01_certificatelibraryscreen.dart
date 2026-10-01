part of '../certificate_library_screen.dart';

class CertificateLibraryScreen extends StatefulWidget {
  const CertificateLibraryScreen({
    super.key,
    required this.database,
    required this.keyStorage,
    this.projectId,
    this.title = 'Certificate library',
  });

  final AppDatabase database;
  final KeyStorage keyStorage;
  final String? projectId;
  final String title;

  @override
  State<CertificateLibraryScreen> createState() =>
      _CertificateLibraryScreenState();
}
