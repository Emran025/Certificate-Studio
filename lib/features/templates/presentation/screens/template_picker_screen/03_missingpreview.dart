part of '../template_picker_screen.dart';

class _MissingPreview extends StatelessWidget {
  const _MissingPreview();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 40),
    ),
  );
}
