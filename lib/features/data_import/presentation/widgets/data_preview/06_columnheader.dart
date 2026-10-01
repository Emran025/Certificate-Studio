part of '../data_preview.dart';

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.column,
    required this.onEdit,
    required this.onDelete,
  });

  final String column;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        column,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
      IconButton(
        tooltip: context.l10n.text('Edit field'),
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
      IconButton(
        tooltip: context.l10n.text('Delete field'),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, size: 18),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    ],
  );
}
