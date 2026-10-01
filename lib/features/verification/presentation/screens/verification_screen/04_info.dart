part of '../verification_screen.dart';

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value ?? context.l10n.text('Not provided'))),
      ],
    ),
  );
}
