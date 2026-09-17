import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/localization/app_localizations.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/certificate_verification_service.dart';
import '../bloc/verification_bloc.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.database,
    required this.keyStorage,
  });
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _idController = TextEditingController();
  final _qrController = TextEditingController();
  late final VerificationBloc _verificationBloc;

  @override
  void initState() {
    super.initState();
    _verificationBloc = VerificationBloc(
      CertificateVerificationService(widget.database, widget.keyStorage),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _qrController.dispose();
    _verificationBloc.close();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    // Use FileType.any instead of an image-only picker on web/desktop. The
    // extension is validated here so PDF certificates are selectable too.
    final picked = await FilePicker.pickFiles(type: FileType.any);
    final file = picked.isEmpty ? null : picked.first;
    if (file == null) return;
    final extension = file.name.split('.').last.toLowerCase();
    const supportedExtensions = {'pdf', 'png', 'jpg', 'jpeg'};
    if (!supportedExtensions.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.text(
                'Please select a PDF, PNG, JPG, or JPEG certificate.',
              ),
            ),
          ),
        );
      }
      return;
    }
    final bytes = await file.readAsBytes();
    _verificationBloc.add(VerifyCertificateFile(bytes, file.name));
  }

  Future<void> _verifyId([String? id]) async {
    final value = (id ?? _idController.text).trim();
    if (value.isEmpty) return;
    _idController.text = value;
    _verificationBloc.add(VerifyCertificateId(value));
  }

  Future<void> _verifyQr() async {
    final value = _qrController.text.trim();
    if (value.isEmpty) return;
    _verificationBloc.add(VerifyQrPayload(value));
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<VerificationBloc, VerificationState>(
    bloc: _verificationBloc,
    builder: (context, state) => Scaffold(
      body: AppPageTable(
        header: AppPageHeader(
          title: context.l10n.text('Verify certificate'),
          subtitle: context.l10n.text(
            'Use the certificate file itself. Verification runs offline from its embedded security record.',
          ),
          icon: Icons.verified_user_outlined,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.text('Certificate file'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.text(
                            'Select an issued certificate. For PNG/JPG images, the QR code is extracted automatically and the result reports extraction success or failure.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: state.status == VerificationStatus.loading
                              ? null
                              : _pickCertificate,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            context.l10n.text('Select certificate file'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.text('QR verification'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.text(
                            'Scan the QR code with your device and paste its cstudio:// payload here.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _qrController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: context.l10n.text('QR payload'),
                            prefixIcon: Icon(Icons.qr_code_2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: state.status == VerificationStatus.loading
                              ? null
                              : _verifyQr,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(context.l10n.text('Verify QR payload')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.text('Certificate ID'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.text(
                            'Additional lookup method for certificates already available in this offline workspace.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            labelText: context.l10n.text('Certificate ID'),
                            hintText: context.l10n.text('certificate-…'),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          onSubmitted: (_) => _verifyId(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: state.status == VerificationStatus.loading
                              ? null
                              : _verifyId,
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            context.l10n.text('Verify certificate ID'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.status == VerificationStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (state.result case final result?) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _ResultCard(result: result),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final CertificateVerificationResult result;
  @override
  Widget build(BuildContext context) {
    final color = result.isValid
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    final title = switch (result.status) {
      CertificateVerificationStatus.valid => context.l10n.text(
        'Valid certificate',
      ),
      CertificateVerificationStatus.integrityCompromised => context.l10n.text(
        'Integrity compromised',
      ),
      CertificateVerificationStatus.invalidSignature => context.l10n.text(
        'Invalid signature',
      ),
      CertificateVerificationStatus.unknownCertificate => context.l10n.text(
        'Unknown certificate',
      ),
      CertificateVerificationStatus.verificationDataMissing =>
        context.l10n.text('Verification data missing'),
      CertificateVerificationStatus.unsupported => context.l10n.text(
        'Unsupported or malformed certificate',
      ),
      CertificateVerificationStatus.failed => context.l10n.text(
        'Verification failed',
      ),
    };
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isValid ? Icons.verified : Icons.gpp_bad_outlined,
                color: color,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (result.qrExtracted) ...[
            _Info(
              label: context.l10n.text('QR extraction'),
              value: context.l10n.text(
                'Success — QR payload was extracted from the image',
              ),
            ),
          ] else if (result.reason?.contains('QR extraction failed') ?? false)
            _Info(
              label: context.l10n.text('QR extraction'),
              value: context.l10n.text(
                'Failed — no readable QR code was found',
              ),
            ),
          if (result.isValid) ...[
            _Info(
              label: context.l10n.text('Certificate ID'),
              value: result.certificateId,
            ),
            _Info(
              label: context.l10n.text('Recipient'),
              value: result.recipient,
            ),
            _Info(
              label: context.l10n.text('Institution'),
              value: result.institution,
            ),
            _Info(
              label: context.l10n.text('Course / project'),
              value: result.course,
            ),
            _Info(
              label: context.l10n.text('Issue date'),
              value: result.issueDate,
            ),
            _Info(
              label: context.l10n.text('Integrity'),
              value: context.l10n.text(
                'Hash matches embedded certificate data',
              ),
            ),
            _Info(
              label: context.l10n.text('Digital signature'),
              value: context.l10n.text('Valid Ed25519 signature'),
            ),
          ] else
            Text(
              result.reason ?? 'The certificate could not be verified.',
              style: TextStyle(color: color),
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value ?? context.l10n.text('Not provided'))),
      ],
    ),
  );
}
