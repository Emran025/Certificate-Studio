import 'package:flutter/material.dart';

import '../../../../config/localization/app_localizations.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/entities/import_merge_plan.dart';

Future<Map<int, ImportMergeDecision>?> showImportConflictDialog(
  BuildContext context,
  ImportMergePlan plan,
) => showDialog<Map<int, ImportMergeDecision>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ImportConflictDialog(plan: plan),
);

class _ImportConflictDialog extends StatefulWidget {
  const _ImportConflictDialog({required this.plan});

  final ImportMergePlan plan;

  @override
  State<_ImportConflictDialog> createState() => _ImportConflictDialogState();
}

class _ImportConflictDialogState extends State<_ImportConflictDialog> {
  final Map<int, ImportMergeDecision> _decisions = {};

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final hasOnlyDuplicates = plan.conflicts.every(
      (item) => item.exactDuplicate,
    );
    return AppDialog(
      width: 760,
      showCloseButton: true,
      icon: Icons.compare_arrows_outlined,
      title: Text(context.l10n.text('Review import changes')),
      subtitle: Text(
        context.l10n.text(
          'Review duplicate rows and choose how to merge them.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.text('Cancel import')),
        ),
        OutlinedButton(
          onPressed: () => _applyToAll(ImportMergeDecision.keepBoth),
          child: Text(context.l10n.text('Keep all as new')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_decisions),
          child: Text(
            context.l10n.text(
              hasOnlyDuplicates ? 'Import without duplicates' : 'Apply choices',
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(plan: plan),
          const SizedBox(height: AppSpacing.md),
          if (plan.conflicts.isEmpty)
            _NoConflicts()
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: plan.conflicts.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _ConflictCard(
                  number: index + 1,
                  conflict: plan.conflicts[index],
                  decision: _decisions[plan.conflicts[index].incomingIndex],
                  onDecision: (decision) => setState(
                    () => _decisions[plan.conflicts[index].incomingIndex] =
                        decision,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _applyToAll(ImportMergeDecision decision) {
    setState(() {
      for (final conflict in widget.plan.conflicts) {
        _decisions[conflict.incomingIndex] = decision;
      }
    });
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan});

  final ImportMergePlan plan;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      _Count(
        icon: Icons.add_circle_outline,
        label: '${plan.newRowCount} ${context.l10n.text('new rows')}',
      ),
      _Count(
        icon: Icons.warning_amber_outlined,
        label: '${plan.conflicts.length} ${context.l10n.text('duplicates')}',
      ),
      _Count(
        icon: Icons.view_column_outlined,
        label: '${plan.newColumnCount} ${context.l10n.text('new columns')}',
      ),
      _Count(
        icon: Icons.link,
        label:
            '${plan.reusedColumnCount} ${context.l10n.text('matching columns')}',
      ),
    ],
  );
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 16), label: Text(label));
}

class _NoConflicts extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    color: Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: .35),
    child: Row(
      children: [
        Icon(Icons.check_circle_outline, color: context.themePrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.text(
              'No duplicate rows found. The new rows will be added safely.',
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.number,
    required this.conflict,
    required this.decision,
    required this.onDecision,
  });

  final int number;
  final ImportConflict conflict;
  final ImportMergeDecision? decision;
  final ValueChanged<ImportMergeDecision> onDecision;

  @override
  Widget build(BuildContext context) {
    final title = conflict.exactDuplicate
        ? context.l10n.text('Exact duplicate')
        : context.l10n.text('Same identity, different values');
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, child: Text('$number')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('$title · ${conflict.identity}')),
              DropdownButton<ImportMergeDecision>(
                value: decision ?? ImportMergeDecision.keepExisting,
                onChanged: (value) {
                  if (value != null) onDecision(value);
                },
                items: [
                  DropdownMenuItem(
                    value: ImportMergeDecision.keepExisting,
                    child: Text(context.l10n.text('Keep existing')),
                  ),
                  DropdownMenuItem(
                    value: ImportMergeDecision.useImported,
                    child: Text(context.l10n.text('Use imported')),
                  ),
                  DropdownMenuItem(
                    value: ImportMergeDecision.keepBoth,
                    child: Text(context.l10n.text('Keep both')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RowComparison(
            label: context.l10n.text('Existing'),
            row: conflict.existingRow,
          ),
          const SizedBox(height: AppSpacing.xs),
          _RowComparison(
            label: context.l10n.text('Imported'),
            row: conflict.incomingRow,
          ),
        ],
      ),
    );
  }
}

class _RowComparison extends StatelessWidget {
  const _RowComparison({required this.label, required this.row});

  final String label;
  final Map<String, String> row;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.input),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Text(
            row.entries
                .where((entry) => entry.value.trim().isNotEmpty)
                .map((entry) => '${entry.key}: ${entry.value}')
                .join(' · '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
