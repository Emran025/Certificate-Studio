part of '../screens/certificate_designer_screen.dart';

const _minimumDesignerFontSize = 8.0;
const _maximumDesignerFontSize = 512.0;

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({
    required this.field,
    required this.columns,
    required this.fontFamilies,
    required this.onChanged,
    required this.onPickTemplateColor,
    required this.onDelete,
    required this.onFontSizeEditingChanged,
  });
  final _DesignerField? field;
  final List<String> columns;
  final List<String> fontFamilies;
  final ValueChanged<_DesignerField> onChanged;
  final Future<String?> Function() onPickTemplateColor;
  final VoidCallback onDelete;
  final ValueChanged<bool> onFontSizeEditingChanged;
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
          if (!selected.qr && selected.text.isEmpty)
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
          if (!selected.qr && selected.text.isNotEmpty)
            TextFormField(
              key: ValueKey('${selected.id}-text'),
              initialValue: selected.text,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.text('Static text'),
              ),
              onChanged: (value) => onChanged(selected.copyWith(text: value)),
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
              minValue: _minimumDesignerFontSize,
              maxValue: _maximumDesignerFontSize,
              updateOnValidInput: true,
              onEditingChanged: onFontSizeEditingChanged,
              onChanged: (value) =>
                  onChanged(selected.copyWith(fontSize: value)),
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
              onPickTemplateColor: onPickTemplateColor,
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
  const _ColorInput({
    required this.value,
    required this.onChanged,
    required this.onPickTemplateColor,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Future<String?> Function() onPickTemplateColor;

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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: InkWell(
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
        ),
      ),
      IconButton(
        tooltip: context.l10n.text('Pick color from template image'),
        onPressed: () async {
          final color = await onPickTemplateColor();
          if (color != null) onChanged(color);
        },
        icon: const Icon(Icons.colorize),
      ),
    ],
  );
}

class _TemplateColorPickerDialog extends StatefulWidget {
  const _TemplateColorPickerDialog({
    required this.imageBytes,
    required this.decodedImage,
  });

  final Uint8List imageBytes;
  final image.Image decodedImage;

  @override
  State<_TemplateColorPickerDialog> createState() =>
      _TemplateColorPickerDialogState();
}

class _TemplateColorPickerDialogState
    extends State<_TemplateColorPickerDialog> {
  String? _selectedHex;

  Color _parse(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = math
        .min(680.0, screenSize.width - 64)
        .clamp(240.0, 680.0)
        .toDouble();
    final imageHeight = math
        .min(420.0, screenSize.height - 280)
        .clamp(180.0, 420.0)
        .toDouble();
    return AppDialog(
      title: Text(context.l10n.text('Pick color from template image')),
      icon: Icons.colorize,
      width: width,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.text('Cancel')),
        ),
        FilledButton(
          onPressed: _selectedHex == null
              ? null
              : () => Navigator.of(context).pop(_selectedHex),
          child: Text(context.l10n.text('Use selected color')),
        ),
      ],
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.text(
                'Choose a point in the template to sample its color.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: imageHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final sourceSize = Size(
                    widget.decodedImage.width.toDouble(),
                    widget.decodedImage.height.toDouble(),
                  );
                  final fitted = applyBoxFit(
                    BoxFit.contain,
                    sourceSize,
                    canvasSize,
                  );
                  final imageRect = Alignment.center.inscribe(
                    fitted.destination,
                    Offset.zero & canvasSize,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final point = details.localPosition;
                      if (!imageRect.contains(point)) return;
                      final x = (point.dx - imageRect.left) / imageRect.width;
                      final y = (point.dy - imageRect.top) / imageRect.height;
                      setState(() {
                        _selectedHex = templatePixelHexColor(
                          widget.decodedImage,
                          x,
                          y,
                        );
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fromRect(
                          rect: imageRect,
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_selectedHex != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _parse(_selectedHex!),
                      border: Border.all(color: Colors.black26),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_selectedHex!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  const _NumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue,
    this.maxValue,
    this.updateOnValidInput = false,
    this.onEditingChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double? minValue;
  final double? maxValue;
  final bool updateOnValidInput;
  final ValueChanged<bool>? onEditingChanged;
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
      widget.onEditingChanged?.call(false);
    } else {
      widget.onEditingChanged?.call(true);
    }
  }

  static String _formatValue(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();

  void _commit() {
    final candidate = _pendingValue ?? double.tryParse(_controller.text.trim());
    if (candidate == null) {
      _controller.value = TextEditingValue(
        text: _formatValue(widget.value),
        selection: TextSelection.collapsed(
          offset: _formatValue(widget.value).length,
        ),
      );
      return;
    }
    final value = _constrain(candidate);
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

  double _constrain(double value) {
    final minimum = widget.minValue;
    if (minimum != null && value < minimum) value = minimum;
    final maximum = widget.maxValue;
    if (maximum != null && value > maximum) value = maximum;
    return value;
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
      final value = double.tryParse(text.trim());
      _pendingValue = value;
      if (widget.updateOnValidInput && value != null) {
        widget.onChanged(_constrain(value));
      }
    },
    onEditingComplete: _commit,
  );
}
