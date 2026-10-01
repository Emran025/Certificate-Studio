part of '../verification_screen.dart';

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
