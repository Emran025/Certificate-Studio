part of '../data_preview.dart';

class _FieldRulesDialog extends StatefulWidget {
  const _FieldRulesDialog({required this.columns, required this.profiles});

  final List<String> columns;
  final Map<String, _FieldProfile> profiles;

  @override
  State<_FieldRulesDialog> createState() => _FieldRulesDialogState();
}

class _FieldRulesDialogState extends State<_FieldRulesDialog> {
  late final Map<String, _FieldKind> _kinds;
  late final Map<String, TextEditingController> _minimums;
  late final Map<String, TextEditingController> _maximums;
  late final Map<String, TextEditingController> _choices;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _kinds = {};
    _minimums = {};
    _maximums = {};
    _choices = {};
    for (final column in widget.columns) {
      final profile = widget.profiles[column]!;
      _kinds[column] = profile.kind;
      _minimums[column] = TextEditingController(
        text: profile.min?.toString() ?? '0',
      );
      _maximums[column] = TextEditingController(
        text: profile.max?.toString() ?? '100',
      );
      _choices[column] = TextEditingController(
        text: profile.choices.join('\n'),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in [
      ..._minimums.values,
      ..._maximums.values,
      ..._choices.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final rules = <String, FieldRule>{};
    for (final column in widget.columns) {
      switch (_kinds[column]!) {
        case _FieldKind.text:
          rules[column] = const FieldRule(kind: FieldRuleKind.text);
        case _FieldKind.number:
          final min = double.tryParse(_minimums[column]!.text.trim());
          final max = double.tryParse(_maximums[column]!.text.trim());
          if (min == null || max == null || !min.isFinite || !max.isFinite) {
            setState(() {
              _errorMessage = context.l10n.text('Enter valid numeric bounds.');
            });
            return;
          }
          if (min > max) {
            setState(() {
              _errorMessage = context.l10n.text(
                'Minimum value must be less than or equal to maximum value.',
              );
            });
            return;
          }
          rules[column] = FieldRule(
            kind: FieldRuleKind.number,
            min: min,
            max: max,
          );
        case _FieldKind.choice:
          final choices = _choices[column]!.text
              .split('\n')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList();
          if (choices.isEmpty) {
            setState(() {
              _errorMessage = context.l10n.text(
                'Add at least one allowed value.',
              );
            });
            return;
          }
          rules[column] = FieldRule(
            kind: FieldRuleKind.choice,
            choices: choices,
          );
        case _FieldKind.phone:
          rules[column] = const FieldRule(kind: FieldRuleKind.phone);
        case _FieldKind.link:
          rules[column] = const FieldRule(kind: FieldRuleKind.link);
      }
    }
    Navigator.of(context).pop(rules);
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: Text(context.l10n.text('Field rules')),
    subtitle: Text(
      context.l10n.text(
        'Configure the type and accepted values for every field.',
      ),
    ),
    icon: Icons.tune,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.text('Cancel')),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.check, size: 18),
        label: Text(context.l10n.text('Save')),
      ),
    ],
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.68,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.columns.length + (_errorMessage == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == widget.columns.length) {
            return Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          }
          return _fieldCard(context, widget.columns[index]);
        },
      ),
    ),
  );

  Widget _fieldCard(BuildContext context, String column) => AppSurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(column, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<_FieldKind>(
          key: ValueKey('field-rule-type-$column'),
          initialValue: _kinds[column],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.text('Field type'),
          ),
          items: [
            DropdownMenuItem(
              value: _FieldKind.text,
              child: Text(context.l10n.text('Free text')),
            ),
            DropdownMenuItem(
              value: _FieldKind.number,
              child: Text(context.l10n.text('Number')),
            ),
            DropdownMenuItem(
              value: _FieldKind.choice,
              child: Text(context.l10n.text('Choice list')),
            ),
            DropdownMenuItem(
              value: _FieldKind.phone,
              child: Text(context.l10n.text('Phone number')),
            ),
            DropdownMenuItem(
              value: _FieldKind.link,
              child: Text(context.l10n.text('Link')),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _kinds[column] = value;
              _errorMessage = null;
            });
          },
        ),
        if (_kinds[column] == _FieldKind.number) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('field-rule-min-$column'),
                  controller: _minimums[column],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.text('Minimum value'),
                  ),
                  onChanged: (_) => _clearError(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: ValueKey('field-rule-max-$column'),
                  controller: _maximums[column],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.text('Maximum value'),
                  ),
                  onChanged: (_) => _clearError(),
                ),
              ),
            ],
          ),
        ],
        if (_kinds[column] == _FieldKind.choice) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: ValueKey('field-rule-choices-$column'),
            controller: _choices[column],
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n.text('Allowed values'),
              helperText: context.l10n.text('Enter one option per line.'),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _clearError(),
          ),
        ],
        if (_kinds[column] == _FieldKind.text) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.text('Text fields accept any value.')),
        ],
        if (_kinds[column] == _FieldKind.phone) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.text('Phone numbers open in the phone app.')),
        ],
        if (_kinds[column] == _FieldKind.link) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.text('Links open in the browser.')),
        ],
      ],
    ),
  );

  void _clearError() {
    if (_errorMessage == null) return;
    setState(() => _errorMessage = null);
  }
}
