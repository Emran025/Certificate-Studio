import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/certificate_verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.database, required this.keyStorage});
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _idController = TextEditingController();
  final _qrController = TextEditingController();
  CertificateVerificationResult? _result;
  bool _checking = false;
  List<String> _recentIds = [];

  CertificateVerificationService get _service => CertificateVerificationService(widget.database, widget.keyStorage);

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final rows = await widget.database.query(DatabaseTables.certificates);
    if (mounted) setState(() => _recentIds = rows.reversed.map((row) => row['id']! as String).take(10).toList());
  }

  Future<void> _pickCertificate() async {
    // Use FileType.any instead of an image-only picker on web/desktop. The
    // extension is validated here so PDF certificates are selectable too.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return;
    final extension = file.name.split('.').last.toLowerCase();
    const supportedExtensions = {'pdf', 'png', 'jpg', 'jpeg'};
    if (!supportedExtensions.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF, PNG, JPG, or JPEG certificate.')),
        );
      }
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) return;
    await _run(() => _service.verifyFile(bytes, fileName: file.name));
  }

  Future<void> _verifyId([String? id]) async {
    final value = (id ?? _idController.text).trim();
    if (value.isEmpty) return;
    _idController.text = value;
    await _run(() => _service.verify(value));
  }

  Future<void> _verifyQr() async {
    final value = _qrController.text.trim();
    if (value.isEmpty) return;
    await _run(() => _service.verifyQr(value));
  }

  Future<void> _run(Future<CertificateVerificationResult> Function() action) async {
    setState(() { _checking = true; _result = null; });
    final result = await action();
    if (mounted) setState(() { _checking = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify certificate')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Verify certificate', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Use the certificate file itself. Verification runs offline from its embedded security record.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Certificate file', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('Select an issued PDF, PNG, JPG, or JPEG certificate. Do not upload a standalone signature.'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(onPressed: _checking ? null : _pickCertificate, icon: const Icon(Icons.upload_file), label: const Text('Select certificate file')),
        ])),
        const SizedBox(height: AppSpacing.md),
        AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('QR verification', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('Scan the QR code with your device and paste its cstudio:// payload here.'),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _qrController, maxLines: 2, decoration: const InputDecoration(labelText: 'QR payload', prefixIcon: Icon(Icons.qr_code_2))),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: _checking ? null : _verifyQr, icon: const Icon(Icons.qr_code_scanner), label: const Text('Verify QR payload')),
        ])),
        const SizedBox(height: AppSpacing.md),
        AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Certificate ID', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('Additional lookup method for certificates already available in this offline workspace.'),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Certificate ID', hintText: 'certificate-…', prefixIcon: Icon(Icons.badge_outlined)), onSubmitted: (_) => _verifyId()),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: _checking ? null : _verifyId, icon: const Icon(Icons.verified_user_outlined), label: const Text('Verify certificate ID')),
        ])),
        if (_checking) const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator())),
        if (_result case final result?) ...[const SizedBox(height: AppSpacing.lg), _ResultCard(result: result)],
        if (_recentIds.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), Text('Recent certificates', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: AppSpacing.sm), AppSurfaceCard(padding: EdgeInsets.zero, child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _recentIds.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, index) => ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: Text(_recentIds[index]), trailing: const Icon(Icons.chevron_right), onTap: () => _verifyId(_recentIds[index]))))],
      ]))),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final CertificateVerificationResult result;
  @override
  Widget build(BuildContext context) {
    final color = result.isValid ? Colors.green : Theme.of(context).colorScheme.error;
    final title = switch (result.status) {
      CertificateVerificationStatus.valid => 'Valid certificate',
      CertificateVerificationStatus.integrityCompromised => 'Integrity compromised',
      CertificateVerificationStatus.invalidSignature => 'Invalid signature',
      CertificateVerificationStatus.unknownCertificate => 'Unknown certificate',
      CertificateVerificationStatus.verificationDataMissing => 'Verification data missing',
      CertificateVerificationStatus.unsupported => 'Unsupported or malformed certificate',
      CertificateVerificationStatus.failed => 'Verification failed',
    };
    return AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(result.isValid ? Icons.verified : Icons.gpp_bad_outlined, color: color, size: 32), const SizedBox(width: AppSpacing.md), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)))]), const SizedBox(height: AppSpacing.md), if (result.isValid) ...[_Info(label: 'Certificate ID', value: result.certificateId), _Info(label: 'Recipient', value: result.recipient), _Info(label: 'Institution', value: result.institution), _Info(label: 'Course / project', value: result.course), _Info(label: 'Issue date', value: result.issueDate), _Info(label: 'Integrity', value: 'Hash matches embedded certificate data'), _Info(label: 'Digital signature', value: 'Valid Ed25519 signature')] else Text(result.reason ?? 'The certificate could not be verified.', style: TextStyle(color: color))]));
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(children: [SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.labelLarge)), Expanded(child: Text(value ?? 'Not provided'))]));
}
