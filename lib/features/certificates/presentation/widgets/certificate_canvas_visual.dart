import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zxing2/qrcode.dart';

/// Interchangeable implementations for the certificate field visual.
abstract interface class CertificateCanvasFieldRenderer {
  Widget render(CertificateCanvasField field);
}

/// The current renderer shared by the designer preview and Flutter export.
class FlutterCertificateCanvasFieldRenderer
    implements CertificateCanvasFieldRenderer {
  const FlutterCertificateCanvasFieldRenderer();

  @override
  Widget render(CertificateCanvasField field) => field;
}

/// Preserves the original designer field drawing for compatibility/testing.
class LegacyCertificateCanvasFieldRenderer
    implements CertificateCanvasFieldRenderer {
  const LegacyCertificateCanvasFieldRenderer();

  @override
  Widget render(CertificateCanvasField field) =>
      _LegacyCertificateCanvasField(field: field);
}

/// The exact field body shared by the designer and generated certificate view.
class CertificateCanvasField extends StatelessWidget {
  const CertificateCanvasField({
    required this.text,
    required this.fontFamily,
    required this.fontFamilies,
    required this.fontSize,
    required this.color,
    required this.alignment,
    required this.direction,
    required this.bold,
    required this.italic,
    this.qr = false,
    this.qrPayload = 'certificate-studio-preview',
    this.qrSize = 96,
    this.selected = false,
    this.selectionColor = Colors.blue,
    this.selectionBorderColor = Colors.blue,
    super.key,
  });

  final String text;
  final String fontFamily;
  final List<String> fontFamilies;
  final double fontSize;
  final String color;
  final String alignment;
  final TextDirection direction;
  final bool bold;
  final bool italic;
  final bool qr;
  final String qrPayload;
  final double qrSize;
  final bool selected;
  final Color selectionColor;
  final Color selectionBorderColor;

  @override
  Widget build(BuildContext context) => Container(
    alignment: switch (alignment) {
      'center' => Alignment.center,
      'right' => Alignment.centerRight,
      _ => Alignment.centerLeft,
    },
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: selected
          ? selectionColor.withValues(alpha: .45)
          : Colors.transparent,
      border: Border.all(
        color: selected ? selectionBorderColor : Colors.transparent,
        width: 2,
      ),
    ),
    child: qr
        ? Center(
            child: CertificateQrCode(payload: qrPayload, size: qrSize),
          )
        : Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.clip,
            textDirection: direction,
            style: TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: [
                ...fontFamilies.where((family) => family != fontFamily),
                'Noto Naskh Arabic',
                'Noto Sans Arabic',
                'Arial',
              ],
              fontSize: fontSize,
              color: _certificateColor(color),
              decoration: TextDecoration.none,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
  );
}

class _LegacyCertificateCanvasField extends StatelessWidget {
  const _LegacyCertificateCanvasField({required this.field});

  final CertificateCanvasField field;

  @override
  Widget build(BuildContext context) => Container(
    alignment: switch (field.alignment) {
      'center' => Alignment.center,
      'right' => Alignment.centerRight,
      _ => Alignment.centerLeft,
    },
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: field.selected
          ? field.selectionColor.withValues(alpha: .45)
          : Colors.transparent,
      border: Border.all(
        color: field.selected ? field.selectionBorderColor : Colors.transparent,
        width: 2,
      ),
    ),
    child: field.qr
        ? const Center(child: Icon(Icons.qr_code_2, size: 96))
        : Text(
            field.text,
            maxLines: 3,
            overflow: TextOverflow.clip,
            textDirection: field.direction,
            style: TextStyle(
              fontFamily: field.fontFamily,
              fontFamilyFallback: [
                ...field.fontFamilies.where(
                  (family) => family != field.fontFamily,
                ),
                'Noto Naskh Arabic',
                'Noto Sans Arabic',
                'Arial',
              ],
              fontSize: field.fontSize,
              color: _legacyCertificateColor(field.color),
              decoration: TextDecoration.none,
              fontWeight: field.bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: field.italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
  );
}

Color _legacyCertificateColor(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF20332B);
}

/// A real QR visual used in both the design preview and the exported canvas.
class CertificateQrCode extends StatelessWidget {
  const CertificateQrCode({
    required this.payload,
    required this.size,
    super.key,
  });

  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) {
    final matrix = Encoder.encode(payload, ErrorCorrectionLevel.l).matrix!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CertificateQrPainter(matrix, payload),
        size: Size.square(size),
      ),
    );
  }
}

class _CertificateQrPainter extends CustomPainter {
  const _CertificateQrPainter(this.matrix, this.payload);

  final dynamic matrix;
  final String payload;

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, white);
    const quietModules = 4;
    final module = size.width / (matrix.width + quietModules * 2);
    for (var row = 0; row < matrix.height; row++) {
      for (var column = 0; column < matrix.width; column++) {
        if (matrix.get(column, row) == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              (quietModules + column) * module,
              (quietModules + row) * module,
              module,
              module,
            ),
            black,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CertificateQrPainter oldDelegate) =>
      oldDelegate.payload != payload;
}

/// Flutter-rendered certificate canvas captured for raster-faithful PDF output.
class CertificateCanvasExportView extends StatelessWidget {
  const CertificateCanvasExportView({
    required this.values,
    required this.fields,
    required this.record,
    required this.templateBytes,
    required this.template,
    required this.fontFamilies,
    this.backgroundImage,
    this.fieldRenderer = const FlutterCertificateCanvasFieldRenderer(),
    super.key,
  });

  final Map<String, dynamic> values;
  final List<Map<String, Object?>> fields;
  final Map<String, dynamic> record;
  final List<int>? templateBytes;
  final Map<String, Object?> template;
  final List<String> fontFamilies;
  final ui.Image? backgroundImage;
  final CertificateCanvasFieldRenderer fieldRenderer;

  @override
  Widget build(BuildContext context) {
    final width = _number(template['width'], 1000);
    final height = _number(template['height'], 700);
    final background = templateBytes;
    final qrPayload = encodeVerificationQrPayload(record);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: backgroundImage != null
                ? RawImage(
                    image: backgroundImage,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
                : background == null || background.isEmpty
                    ? const ColoredBox(color: Colors.white)
                    : Image.memory(
                        Uint8List.fromList(background),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
          ),
          for (final field in fields)
            if (_fieldIsVisible(field))
              _exportField(field, width, height, qrPayload),
        ],
      ),
    );
  }

  Widget _exportField(
    Map<String, Object?> field,
    double canvasWidth,
    double canvasHeight,
    String qrPayload,
  ) {
    final position = _jsonMap(field['position_json']);
    final style = _jsonMap(field['style_json']);
    final x = _number(position['x'], 100);
    final y = _number(position['y'], 100);
    final width = _number(position['width'], 420);
    final height = _number(position['height'], 64);
    final qr = style['kind'] == 'qr';
    final qrSize = math.max(1.0, math.min(width, height) - 20);

    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: fieldRenderer.render(
        CertificateCanvasField(
          text: certificateCanvasText(
            values: values,
            source: field['source']?.toString() ?? '',
            staticText: style['text']?.toString() ?? '',
          ),
          fontFamily: style['font_family']?.toString() ?? 'Cairo',
          fontFamilies: fontFamilies,
          fontSize: _number(style['font_size'], 28),
          color: style['color']?.toString() ?? '#20332B',
          alignment: style['alignment']?.toString() ?? 'left',
          direction: style['direction'] == 'rtl'
              ? TextDirection.rtl
              : TextDirection.ltr,
          bold: style['bold'] == true || style['font_weight'] == 'bold',
          italic: style['italic'] == true,
          qr: qr,
          qrPayload: qrPayload,
          qrSize: qrSize,
        ),
      ),
    );
  }

  bool _fieldIsVisible(Map<String, Object?> field) =>
      _jsonMap(field['style_json'])['visible'] != false;
}

/// Resolves text and missing-value fallbacks identically for preview and export.
String certificateCanvasText({
  required Map<String, dynamic> values,
  required String source,
  String staticText = '',
}) {
  if (staticText.isNotEmpty) return staticText;
  final value = _certificateCanvasValueForKey(values, source);
  return value == null ? source : '$value';
}

dynamic _certificateCanvasValueForKey(Map<String, dynamic> values, String key) {
  final exact = values[key];
  if (exact != null) return exact;
  final normalizedKey = _normalizeCertificateKey(key);
  for (final entry in values.entries) {
    if (_normalizeCertificateKey(entry.key) == normalizedKey) {
      return entry.value;
    }
  }
  return null;
}

String _normalizeCertificateKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// Mounted in the generation screen and used to snapshot the exact Flutter
/// field widgets before the PDF is assembled. It must stay in the painted tree.
class CertificateCanvasSnapshotHost extends StatefulWidget {
  const CertificateCanvasSnapshotHost({
    this.fieldRenderer = const FlutterCertificateCanvasFieldRenderer(),
    super.key,
  });

  final CertificateCanvasFieldRenderer fieldRenderer;

  @override
  State<CertificateCanvasSnapshotHost> createState() =>
      CertificateCanvasSnapshotHostState();
}

class CertificateCanvasSnapshotHostState
    extends State<CertificateCanvasSnapshotHost> {
  final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'certificate-canvas');
  final Set<String> _loadedFontFamilies = {'Cairo'};
  Widget? _captureChild;
  bool _capturing = false;

  Future<List<int>> capture({
    required Map<String, dynamic> values,
    required List<Map<String, Object?>> fields,
    required Map<String, dynamic> record,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
    required Map<String, List<int>> fontBytesByFamily,
  }) async {
    if (_capturing) {
      throw StateError('A certificate canvas capture is already running.');
    }
    _capturing = true;
    ui.Image? image;
    ui.Image? decodedBackground;
    try {
      if (templateBytes != null && templateBytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(
          Uint8List.fromList(templateBytes),
        );
        try {
          decodedBackground = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      }
      if (!mounted) throw StateError('The certificate screen was closed.');
      await _loadFonts(fontBytesByFamily);

      final fontFamilies = <String>{
        'Cairo',
        'Arial',
        'sans-serif',
        ...fontBytesByFamily.keys,
      }.toList();
      final view = CertificateCanvasExportView(
        values: values,
        fields: fields,
        record: record,
        templateBytes: templateBytes,
        template: template,
        fontFamilies: fontFamilies,
        backgroundImage: decodedBackground,
        fieldRenderer: widget.fieldRenderer,
      );
      if (!mounted) throw StateError('The certificate screen was closed.');
      setState(() {
        _captureChild = RepaintBoundary(key: _boundaryKey, child: view);
      });
      await WidgetsBinding.instance.endOfFrame;

      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('The certificate canvas is not ready to capture.');
      }
      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }

      final templateDpi = _number(template['dpi'], 96).clamp(1, 1200);
      const targetDpi = 300.0;
      final requestedPixelRatio = targetDpi / templateDpi;
      // Keep the same full 300-DPI raster scale as the PDF export path. A side
      // cap here used to downsample the complete certificate, including QR
      // modules, before saving the PNG.
      image = await renderObject.toImage(pixelRatio: requestedPixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Unable to encode canvas snapshot.');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      if (mounted && _captureChild != null) {
        setState(() => _captureChild = null);
        await WidgetsBinding.instance.endOfFrame;
      }
      decodedBackground?.dispose();
      _capturing = false;
    }
  }

  Future<void> _loadFonts(Map<String, List<int>> fontBytesByFamily) async {
    for (final entry in fontBytesByFamily.entries) {
      final family = entry.key.trim();
      if (family.isEmpty || _loadedFontFamilies.contains(family)) continue;
      try {
        final loader = FontLoader(family)
          ..addFont(
            Future.value(ByteData.sublistView(Uint8List.fromList(entry.value))),
          );
        await loader.load();
        _loadedFontFamilies.add(family);
      } on Object {
        // A font loaded earlier by the designer remains registered with Flutter.
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      _captureChild ?? const SizedBox.shrink();
}

Map<String, dynamic> _jsonMap(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is! String || raw.isEmpty) return {};
  final value = jsonDecode(raw);
  return value is Map ? Map<String, dynamic>.from(value) : {};
}

double _number(Object? value, double fallback) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

Color _certificateColor(String value) {
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse('FF$hex', radix: 16);
  return Color(parsed ?? 0xFF20332B);
}
