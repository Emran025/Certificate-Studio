part of '../screens/certificate_designer_screen.dart';

class _ElementsPanel extends StatelessWidget {
  const _ElementsPanel({
    required this.columns,
    required this.fields,
    required this.selectedId,
    required this.onAdd,
    required this.onAddStaticText,
    required this.onAddQr,
    required this.onSelect,
  });
  final List<String> columns;
  final List<_DesignerField> fields;
  final String? selectedId;
  final VoidCallback onAdd;
  final VoidCallback onAddStaticText;
  final VoidCallback onAddQr;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.themeSurface,
      border: Border(right: BorderSide(color: context.themeBorder)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.text('Elements'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: columns.isEmpty ? null : onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.text('Data field')),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddStaticText,
            icon: const Icon(Icons.title),
            label: Text(context.l10n.text('Static text')),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddQr,
            icon: const Icon(Icons.qr_code_2),
            label: Text(context.l10n.text('QR code')),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.text('Layers'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (fields.isEmpty)
          Text(
            context.l10n.text(
              'Add a field from imported data to start designing.',
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              for (final field in fields)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    selected: field.id == selectedId,
                    dense: true,
                    leading: Icon(
                      field.qr ? Icons.qr_code_2 : Icons.text_fields,
                      size: 18,
                    ),
                    title: Text(
                      field.qr
                          ? 'Verification QR'
                          : field.text.isNotEmpty
                          ? field.text
                          : field.source,
                    ),
                    subtitle: Text(
                      '${field.width.round()} × ${field.height.round()}',
                    ),
                    onTap: () => onSelect(field.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
