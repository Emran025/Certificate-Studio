part of '../fonts_library_screen.dart';

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.font,
    required this.previewText,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.selected,
    required this.compact,
    required this.onUse,
    required this.onDelete,
  });

  final FontAsset font;
  final String previewText;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool selected;
  final bool compact;
  final VoidCallback? onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final previewStyle = TextStyle(
      fontFamily: font.family,
      fontSize: compact ? 16 : 22,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
    );
    final actions = <Widget>[
      if (onUse != null)
        TextButton(
          onPressed: selected ? null : onUse,
          child: Text(
            selected ? context.l10n.text('In use') : context.l10n.text('Use'),
          ),
        ),
      IconButton(
        tooltip: context.l10n.text('Delete'),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ];

    return AppSurfaceCard(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.text_fields, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        font.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: previewStyle,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.l10n.text(
                    '${font.family} · ${font.format.toUpperCase()}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.text_fields)),
                title: Text(font.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: previewStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.text(
                        '${font.family} · ${font.format.toUpperCase()}\n${font.filePath}',
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
            ),
    );
  }
}
