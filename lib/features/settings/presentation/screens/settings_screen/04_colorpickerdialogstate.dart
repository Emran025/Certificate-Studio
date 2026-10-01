part of '../settings_screen.dart';

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _color = HSVColor.fromColor(widget.initialColor);

  void _updateSaturationAndValue(Offset position, Size size) {
    setState(() {
      _color = _color
          .withSaturation((position.dx / size.width).clamp(0.0, 1.0))
          .withValue((1 - position.dy / size.height).clamp(0.0, 1.0));
    });
  }

  void _updateHue(Offset position, Size size) {
    setState(() {
      _color = _color.withHue(
        (position.dx / size.width * 360).clamp(0.0, 360.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _color.toColor();
    return AppDialog(
      title: Text(widget.title),
      icon: Icons.colorize,
      width: 420,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.closeLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: Text(widget.applyLabel),
        ),
      ],
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 190);
                return GestureDetector(
                  onPanDown: (details) =>
                      _updateSaturationAndValue(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _updateSaturationAndValue(details.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: _SaturationValuePainter(hue: _color.hue),
                    foregroundPainter: _SelectionPainter(
                      x: _color.saturation * size.width,
                      y: (1 - _color.value) * size.height,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 24);
                return GestureDetector(
                  onPanDown: (details) =>
                      _updateHue(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _updateHue(details.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: const _HuePainter(),
                    foregroundPainter: _HueSelectionPainter(
                      x: _color.hue / 360 * size.width,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
