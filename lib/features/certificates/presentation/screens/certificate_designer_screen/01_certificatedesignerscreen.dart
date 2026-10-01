part of '../certificate_designer_screen.dart';

class CertificateDesignerScreen extends StatefulWidget {
  const CertificateDesignerScreen({
    super.key,
    required this.database,
    required this.projectId,
    required this.projectName,
  });

  final AppDatabase database;
  final String projectId;
  final String projectName;

  @override
  State<CertificateDesignerScreen> createState() =>
      _CertificateDesignerScreenState();
}

final class _SaveIntent extends Intent {
  const _SaveIntent();
}

final class _UndoIntent extends Intent {
  const _UndoIntent();
}

final class _RedoIntent extends Intent {
  const _RedoIntent();
}
