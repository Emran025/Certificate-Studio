part of '../template_picker_screen.dart';

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
    required this.projectMode,
  });
  final TemplateAsset template;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool projectMode;

  @override
  Widget build(BuildContext context) {
    final path = template.filePath;
    final exists = templateFileExists(path);
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: exists ? templatePreview(path) : const _MissingPreview(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${template.width} × ${template.height} · ${template.format.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!exists)
                  Text(
                    context.l10n.text('File not found at saved path'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: projectMode && selected
                          ? Text(
                              context.l10n.text('Selected'),
                              style: TextStyle(color: Colors.green),
                            )
                          : projectMode
                          ? TextButton(
                              onPressed: onSelect,
                              child: Text(context.l10n.text('Use template')),
                            )
                          : TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(context.l10n.text('Edit template')),
                            ),
                    ),
                    IconButton(
                      tooltip: context.l10n.text('Delete'),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
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
}
