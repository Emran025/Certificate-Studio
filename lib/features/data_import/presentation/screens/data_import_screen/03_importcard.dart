part of '../data_import_screen.dart';

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.controller,
    required this.saving,
    required this.onPickExcel,
    required this.onPaste,
    required this.onImport,
    this.errorMessage,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onPickExcel;
  final VoidCallback onPaste;
  final VoidCallback onImport;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: context.l10n.text('Paste table data'),
            hintText: context.l10n.text('tableDataExample'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppSecondaryButton(
              label: context.l10n.text('Choose Excel file'),
              icon: Icons.table_view_outlined,
              onPressed: saving ? null : onPickExcel,
            ),
            AppSecondaryButton(
              label: context.l10n.text('Paste from clipboard'),
              icon: Icons.content_paste,
              onPressed: saving ? null : onPaste,
            ),
            AppPrimaryButton(
              label: saving
                  ? context.l10n.text('Saving...')
                  : context.l10n.text('Import data'),
              icon: Icons.file_download_outlined,
              onPressed: saving ? null : onImport,
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.text(errorMessage!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.themeError),
          ),
        ],
      ],
    ),
  );
}
