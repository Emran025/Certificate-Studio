part of '../data_preview.dart';

class _MobileRecordCard extends StatelessWidget {
  const _MobileRecordCard({
    required this.row,
    required this.columns,
    required this.rowNumber,
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
    required this.onEditColumn,
    required this.onDeleteColumn,
  });

  final Map<String, String> row;
  final List<String> columns;
  final int rowNumber;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onEditColumn;
  final ValueChanged<String> onDeleteColumn;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.text('Record row {number}', {
                      'number': '$rowNumber',
                    }),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.text('Edit record'),
                  onPressed: disabled ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: context.l10n.text('Delete record row'),
                  onPressed: disabled ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (var index = 0; index < columns.length; index++) ...[
                  _MobileRecordField(
                    column: columns[index],
                    value: row[columns[index]] ?? '',
                    disabled: disabled,
                    onEdit: () => onEditColumn(columns[index]),
                    onDelete: () => onDeleteColumn(columns[index]),
                  ),
                  if (index < columns.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
