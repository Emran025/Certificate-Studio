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
                    : certificateCanvasText(
                        values: previewData,
                        source: field.source,
                        staticText: field.text,
                      ),
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
          CertificateCanvasField(
            text: previewText,
            fontFamily: field.fontFamily,
            fontFamilies: fontFamilies,
            fontSize: field.fontSize,
            color: field.color,
            alignment: field.alignment,
            direction: field.textDirection,
            bold: field.bold,
            italic: field.italic,
            qr: field.qr,
            qrPayload: 'certificate-studio-preview-verification',
            qrSize: math
                .max(1.0, math.min(field.width, field.height) - 20)
                .toDouble(),
            selected: selected,
            selectionColor: context.themeSelection,
            selectionBorderColor: context.themePrimary,
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
