part of '../certificate_library_screen.dart';

class _CertificateDetails extends StatelessWidget {
  const _CertificateDetails({
    required this.certificate,
    required this.database,
    required this.keyStorage,
  });
  final _LibraryCertificate certificate;
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  Widget build(BuildContext context) => Container(
    color: context.themeBackground,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: ListView(
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.themeSelection,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: context.themePrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.text('Certificate details'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _Detail(
                icon: Icons.person_outline,
                label: context.l10n.text('Recipient'),
                value: certificate.recipient.isEmpty
                    ? context.l10n.text('Unavailable')
                    : certificate.recipient,
              ),
              _Detail(
                icon: Icons.verified_outlined,
                label: context.l10n.text('Status'),
                value: context.l10n.text(certificate.status),
              ),
              _Detail(
                icon: Icons.tag_outlined,
                label: context.l10n.text('Identifier'),
                value: certificate.id,
              ),
              _Detail(
                icon: Icons.image_outlined,
                label: context.l10n.text('PNG'),
                value: certificate.imageReference == null
                    ? context.l10n.text('Unavailable')
                    : context.l10n.text('Available'),
              ),
              _Detail(
                icon: Icons.picture_as_pdf_outlined,
                label: context.l10n.text('PDF'),
                value: certificate.pdfReference == null
                    ? context.l10n.text('Unavailable')
                    : context.l10n.text('Available'),
                showDivider: false,
              ),
            ],
          ),
        ),
        const Divider(height: AppSpacing.xl),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: context.themePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.text('Security'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Detail(
                icon: Icons.fingerprint,
                label: context.l10n.text('Document hash'),
                value: certificate.documentHash ??
                    context.l10n.text('Unavailable'),
                showDivider: false,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await CertificateVerificationService(
                      database,
                      keyStorage,
                    ).verify(certificate.id);
                    if (context.mounted) {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AppDialog(
                          title: Text(
                            result.isValid
                                ? context.l10n.text('Valid signature')
                                : context.l10n.text('Verification failed'),
                          ),
                          icon: result.isValid
                              ? Icons.verified
                              : Icons.error_outline,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.l10n.text('Close')),
                            ),
                          ],
                          child: Text(
                            result.isValid
                                ? context.l10n.text(
                                    'The certificate is authentic.',
                                  )
                                : result.reason ??
                                      context.l10n.text('Unable to verify.'),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(context.l10n.text('Verify certificate')),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
