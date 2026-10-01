part of '../data_import_screen.dart';

class _EmptyImportState extends StatelessWidget {
  const _EmptyImportState();

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Row(
      children: [
        Icon(Icons.info_outline, color: context.themePrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.text(
              'No recipient data yet. Import a table to continue to certificate design.',
            ),
          ),
        ),
      ],
    ),
  );
}
