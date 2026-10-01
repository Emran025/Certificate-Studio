part of '../certificate_library_screen.dart';

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.certificate,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
    required this.onVerify,
    required this.onExport,
  });
  final _LibraryCertificate certificate;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final VoidCallback onVerify;
  final ValueChanged<String> onExport;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _ArtifactImage(
                  reference: certificate.imageReference,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onSelected(value ?? false),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: AppStatusBadge(
                  label: context.l10n.text(certificate.status),
                  color: AppColors.success,
                  backgroundColor: AppColors.successSurface,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certificate.recipient.isEmpty
                    ? 'Recipient unavailable'
                    : certificate.recipient,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                certificate.secondaryLabel.isEmpty
                    ? context.l10n.text('Certificate data unavailable')
                    : certificate.secondaryLabel,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.l10n.text('View')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: context.l10n.text('Verify'),
                    onPressed: onVerify,
                    icon: const Icon(Icons.verified_user_outlined),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onExport,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'png',
                        child: Text(context.l10n.text('Export PNG')),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text(context.l10n.text('Export PDF')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
