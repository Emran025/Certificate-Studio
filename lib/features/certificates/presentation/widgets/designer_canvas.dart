part of '../screens/certificate_designer_screen.dart';

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.fields,
    required this.selectedId,
    required this.previewData,
    required this.templatePath,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.zoom,
    required this.fontFamilies,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });
  final List<_DesignerField> fields;
  final String? selectedId;
  final Map<String, dynamic> previewData;
  final String templatePath;
  final double canvasWidth;
  final double canvasHeight;
  final double zoom;
  final List<String> fontFamilies;
  final ValueChanged<String> onSelect;
  final void Function(String, Offset) onMove;
  final void Function(
    String,
    Offset, {
    required bool fromLeft,
    required bool fromTop,
  })
  onResize;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    constrained: false,
    minScale: .4,
    maxScale: 2.2,
    boundaryMargin: const EdgeInsets.all(160),
    child: Transform.scale(
      scale: zoom,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: templateFileExists(templatePath)
                  ? templateCanvasPreview(templatePath)
                  : Container(
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          context.l10n.text('Template image unavailable'),
                        ),
                      ),
                    ),
            ),
            for (final field in fields)
              _CanvasField(
                field: field,
                selected: field.id == selectedId,
                previewText: field.qr
                    ? 'QR'
                    : field.text.isNotEmpty
                    ? field.text
                    : '${previewData[field.source] ?? field.source}',
                fontFamilies: fontFamilies,
                onSelect: () => onSelect(field.id),
                onMove: (delta) => onMove(field.id, delta),
                onResize: (delta, fromLeft, fromTop) => onResize(
                  field.id,
                  delta,
                  fromLeft: fromLeft,
                  fromTop: fromTop,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CanvasField extends StatelessWidget {
  const _CanvasField({
    required this.field,
    required this.selected,
    required this.previewText,
    required this.fontFamilies,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });
  final _DesignerField field;
  final bool selected;
  final String previewText;
  final List<String> fontFamilies;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final void Function(Offset, bool, bool) onResize;
  @override
  Widget build(BuildContext context) => Positioned(
    left: field.x,
    top: field.y,
    width: field.width,
    height: field.height,
    child: GestureDetector(
      onTap: onSelect,
      onPanStart: (_) => onSelect(),
      onPanUpdate: (details) => onMove(details.delta),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: field.textAlignment,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? context.themeSelection.withValues(alpha: .45)
                  : Colors.transparent,
              border: Border.all(
                color: selected ? context.themePrimary : Colors.transparent,
                width: 2,
              ),
            ),
            child: field.qr
                ? const Center(child: Icon(Icons.qr_code_2, size: 96))
                : Text(
                    previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: field.textDirection,
                    style: TextStyle(
                      fontFamily: field.fontFamily,
                      // Keep the chosen family first, then let Flutter use a
                      // platform Arabic font for missing glyphs. This does not
                      // alter layout constraints or the user's font choice.
                      fontFamilyFallback: [
                        ...fontFamilies.where(
                          (family) => family != field.fontFamily,
                        ),
                        'Noto Naskh Arabic',
                        'Noto Sans Arabic',
                        'Arial',
                      ],
                      fontSize: field.fontSize,
                      color: _hex(field.color),
                      fontWeight: field.bold
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontStyle: field.italic
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
          ),
          if (selected) ...[
            _ResizeHandle(
              alignment: Alignment.topLeft,
              onDrag: (delta) => onResize(delta, true, true),
            ),
            _ResizeHandle(
              alignment: Alignment.topRight,
              onDrag: (delta) => onResize(delta, false, true),
            ),
            _ResizeHandle(
              alignment: Alignment.bottomLeft,
              onDrag: (delta) => onResize(delta, true, false),
            ),
            _ResizeHandle(
              alignment: Alignment.bottomRight,
              onDrag: (delta) => onResize(delta, false, false),
            ),
          ],
        ],
      ),
    ),
  );
  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF20332B);
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.alignment, required this.onDrag});
  final Alignment alignment;
  final ValueChanged<Offset> onDrag;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: context.themePrimary,
          border: Border.all(color: Colors.white, width: 2),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
