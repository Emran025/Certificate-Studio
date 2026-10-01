part of '../fonts_library_screen.dart';

class _FontPreviewEditor extends StatelessWidget {
  const _FontPreviewEditor({
    required this.controller,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onUnderlineChanged,
  });

  final TextEditingController controller;
  final bool bold;
  final bool italic;
  final bool underline;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<bool> onUnderlineChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('Live font preview'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.text(
              'Write a sample to compare how every imported font renders it.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.text('Preview text'),
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              FilterChip(
                label: const Text('B'),
                selected: bold,
                onSelected: onBoldChanged,
              ),
              FilterChip(
                label: const Text('I'),
                selected: italic,
                onSelected: onItalicChanged,
              ),
              FilterChip(
                label: const Text('U'),
                selected: underline,
                onSelected: onUnderlineChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
