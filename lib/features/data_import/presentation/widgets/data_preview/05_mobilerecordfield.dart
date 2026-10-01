part of '../data_preview.dart';

class _MobileRecordField extends StatelessWidget {
  const _MobileRecordField({
    required this.column,
    required this.value,
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
  });

  final String column;
  final String value;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.themeMutedText,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(column, style: labelStyle)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
          IconButton(
            tooltip: context.l10n.text('Edit field'),
            onPressed: disabled ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            tooltip: context.l10n.text('Delete field'),
            onPressed: disabled ? null : onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
