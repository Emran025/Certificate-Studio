part of '../verification_screen.dart';

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color),
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
