part of '../data_preview.dart';

class _RecordEditorState extends State<_RecordEditor> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String?> _choices;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final column in widget.columns)
        column: TextEditingController(text: widget.initialValues[column] ?? ''),
    };
    _choices = {
      for (final column in widget.columns) column: _initialChoice(column),
    };
  }

  String? _initialChoice(String column) {
    final profile = widget.profiles[column];
    if (profile?.kind != _FieldKind.choice) return null;
    final initial = widget.initialValues[column];
    if (initial == null || !profile!.choices.contains(initial)) return null;
    return initial;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    for (final column in widget.columns) {
      final profile = widget.profiles[column]!;
      final value = profile.kind == _FieldKind.choice
          ? (_choices[column] ?? '')
          : _controllers[column]!.text.trim();
      if (profile.kind == _FieldKind.number && value.isNotEmpty) {
        final number = double.tryParse(value);
        if (number == null || number < profile.min! || number > profile.max!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.text('Value must be between {min} and {max}.', {
                  'min': profile.min!.toStringAsFixed(0),
                  'max': profile.max!.toStringAsFixed(0),
                }),
              ),
            ),
          );
          return;
        }
      }
    }
    Navigator.of(context).pop({
      for (final column in widget.columns)
        column: widget.profiles[column]!.kind == _FieldKind.choice
            ? (_choices[column] ?? '')
            : _controllers[column]!.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPortrait = size.height >= size.width;

    return AppDialog(
      title: Text(context.l10n.text('Edit record')),
      icon: Icons.edit_outlined,
      width: isPortrait ? size.width * .8 : size.width * .65,
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
        constraints: BoxConstraints(maxHeight: size.height - AppSpacing.xl * 5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final column in widget.columns) _field(context, column),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, String column) {
    final profile = widget.profiles[column]!;
    if (profile.kind == _FieldKind.choice) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: DropdownButtonFormField<String>(
          initialValue: _choices[column],
          decoration: InputDecoration(
            labelText: column,
            helperText: context.l10n.text('Detected fixed values'),
          ),
          items: [
            for (final choice in profile.choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: (value) => setState(() => _choices[column] = value),
        ),
      );
    }
    final hint = profile.kind == _FieldKind.number
        ? '${profile.min!.toStringAsFixed(0)} - ${profile.max!.toStringAsFixed(0)}'
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: _controllers[column],
        keyboardType: profile.kind == _FieldKind.number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(labelText: column, helperText: hint),
      ),
    );
  }
}
