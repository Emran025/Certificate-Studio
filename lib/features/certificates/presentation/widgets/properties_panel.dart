part of '../screens/certificate_designer_screen.dart';

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({
    required this.field,
    required this.columns,
    required this.fontFamilies,
    required this.onChanged,
    required this.onDelete,
  });
  final _DesignerField? field;
  final List<String> columns;
  final List<String> fontFamilies;
  final ValueChanged<_DesignerField> onChanged;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final selected = field;
    if (selected == null) {
      return Center(
        child: Text(
          context.l10n.text('Select a field to edit its properties.'),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(left: BorderSide(color: context.themeBorder)),
      ),
      child: ListView(
        children: [
          Text(
            'Field properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!selected.qr)
            DropdownButtonFormField<String>(
              initialValue: columns.contains(selected.source)
                  ? selected.source
                  : null,
              decoration: InputDecoration(
                labelText: context.l10n.text('Data source field'),
              ),
              items: [
                for (final column in columns)
                  DropdownMenuItem(value: column, child: Text(column)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(
                    selected.copyWith(
                      source: value,
                      className: canonicalFieldClassId(value),
                    ),
                  );
                }
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.text('Position and size'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-x'),
                  label: 'X',
                  value: selected.x,
                  onChanged: (value) => onChanged(selected.copyWith(x: value)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-y'),
                  label: 'Y',
                  value: selected.y,
                  onChanged: (value) => onChanged(selected.copyWith(y: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-width'),
                  label: context.l10n.text('Width'),
                  value: selected.width,
                  onChanged: (value) => onChanged(
                    selected.copyWith(
                      width: value,
                      height: selected.qr ? value : selected.height,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-height'),
                  label: context.l10n.text('Height'),
                  value: selected.height,
                  onChanged: (value) => onChanged(
                    selected.copyWith(
                      width: selected.qr ? value : selected.width,
                      height: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!selected.qr) ...[
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selected.fontFamily,
              decoration: InputDecoration(
                labelText: context.l10n.text('Font family'),
              ),
              isExpanded: true,
              items: [
                for (final family in fontFamilies)
                  DropdownMenuItem(value: family, child: Text(family)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(selected.copyWith(fontFamily: value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumberInput(
              key: ValueKey('${selected.id}-font-size'),
              label: context.l10n.text('Font size'),
              value: selected.fontSize,
              onChanged: (value) =>
                  onChanged(selected.copyWith(fontSize: value.clamp(8, 180))),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selected.alignment,
              decoration: InputDecoration(
                labelText: context.l10n.text('Text alignment'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'left',
                  child: Text(context.l10n.text('Left')),
                ),
                DropdownMenuItem(
                  value: 'center',
                  child: Text(context.l10n.text('Center')),
                ),
                DropdownMenuItem(
                  value: 'right',
                  child: Text(context.l10n.text('Right')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(selected.copyWith(alignment: value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selected.direction,
              decoration: InputDecoration(
                labelText: context.l10n.text('Text direction'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ltr',
                  child: Text(context.l10n.text('LTR')),
                ),
                DropdownMenuItem(
                  value: 'rtl',
                  child: Text(context.l10n.text('RTL')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(selected.copyWith(direction: value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.text('Bold')),
                value: selected.bold,
                onChanged: (value) => onChanged(selected.copyWith(bold: value)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.text('Italic')),
                value: selected.italic,
                onChanged: (value) =>
                    onChanged(selected.copyWith(italic: value)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ColorInput(
              value: selected.color,
              onChanged: (color) => onChanged(selected.copyWith(color: color)),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: Text(context.l10n.text('Delete field')),
          ),
        ],
      ),
    );
  }
}

class _ColorInput extends StatelessWidget {
  const _ColorInput({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  Color _parse(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF20332B);
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _openPicker(BuildContext context) async {
    final controller = TextEditingController(text: value);
    final palette = [
      Colors.black,
      Colors.white,
      const Color(0xFF20332B),
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: Text(context.l10n.text('Text color')),
        icon: Icons.palette_outlined,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.text('Close')),
          ),
        ],
        child: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: context.l10n.text('Color (#RRGGBB)'),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: _parse(controller.text),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  onChanged: (text) {
                    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(text)) {
                      onChanged(text.toUpperCase());
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final color in palette)
                      InkWell(
                        onTap: () {
                          final hex = _hex(color);
                          controller.text = hex;
                          onChanged(hex);
                          Navigator.pop(dialogContext);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.computeLuminance() > .7
                                  ? Colors.black26
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _openPicker(context),
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: context.l10n.text('Text color'),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _parse(value),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value.toUpperCase()),
        ],
      ),
    ),
  );
}

class _NumberInput extends StatefulWidget {
  const _NumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _controller = TextEditingController(
    text: _formatValue(widget.value),
  );
  late final FocusNode _focusNode = FocusNode();
  double? _pendingValue;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  static String _formatValue(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();

  void _commit() {
    final value = _pendingValue ?? double.tryParse(_controller.text.trim());
    if (value == null) {
      _controller.value = TextEditingValue(
        text: _formatValue(widget.value),
        selection: TextSelection.collapsed(
          offset: _formatValue(widget.value).length,
        ),
      );
      return;
    }
    _pendingValue = null;
    widget.onChanged(value);
    final text = _formatValue(value);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent rebuilds after every valid keystroke. Never replace the
    // controller text while the user is editing, otherwise deleting a value
    // or inserting a digit moves the caret and restores the previous value.
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      final text = _formatValue(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focusNode,
    decoration: InputDecoration(labelText: widget.label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.done,
    onChanged: (text) {
      _pendingValue = double.tryParse(text.trim());
    },
    onEditingComplete: _commit,
  );
}
