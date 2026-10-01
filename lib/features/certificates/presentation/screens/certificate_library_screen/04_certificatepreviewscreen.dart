part of '../certificate_library_screen.dart';

class _CertificatePreviewScreen extends StatelessWidget {
  const _CertificatePreviewScreen({
    required this.certificate,
    required this.database,
    required this.keyStorage,
    required this.exporter,
    required this.fileName,
  });
  final _LibraryCertificate certificate;
  final AppDatabase database;
  final KeyStorage keyStorage;
  final CertificateExportServiceContract exporter;
  final String fileName;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPageTable(
      header: AppPageHeader(
        title: certificate.recipient.isEmpty
            ? context.l10n.text('Certificate preview')
            : certificate.recipient,
        subtitle: context.l10n.text(
          'Preview, verify, and export this generated certificate.',
        ),
        icon: Icons.workspace_premium_outlined,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final path = await exporter.exportSingle(
                certificate: _exportRow(certificate),
                extension: value,
                fileName: fileName,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      path == null
                          ? context.l10n.text('File unavailable.')
                          : context.l10n.text(
                              'Certificate exported successfully.',
                            ),
                    ),
                  ),
                );
              }
            },
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
          IconButton(
            tooltip: context.l10n.text('Back'),
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              context.l10n.text('Back') == "Back"
                  ? Icons.arrow_back
                  : Icons.arrow_forward,
            ),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.tablet;
          final image = InteractiveViewer(
            minScale: .5,
            maxScale: 4,
            child: compact
                ? SizedBox(
                    width: constraints.maxWidth,
                    height: 320,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _ArtifactImage(
                        reference: certificate.imageReference,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _ArtifactImage(
                        reference: certificate.imageReference,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          );
          final details = _CertificateDetails(
            certificate: certificate,
            database: database,
            keyStorage: keyStorage,
          );

          if (compact) {
            return Column(
              children: [
                Expanded(child: image),
                SizedBox(height: 390, width: double.infinity, child: details),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: image),
              SizedBox(width: 340, child: details),
            ],
          );
        },
      ),
    ),
  );
}
