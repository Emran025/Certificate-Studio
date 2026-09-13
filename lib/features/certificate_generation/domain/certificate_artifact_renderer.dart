import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:zxing2/qrcode.dart';

class CertificateArtifactRenderer {
  static Future<List<int>> renderPdf({
    required Map<String, dynamic> values,
    required List<Map<String, Object?>> fields,
    required String hash,
    required Map<String, dynamic> record,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
    required List<int> fontBytes,
  }) async {
    final document = pw.Document(title: 'Certificate');
    final font = pw.Font.ttf(
      ByteData.sublistView(Uint8List.fromList(fontBytes)),
    );
    final canvasWidth = _number(template['width'], 1000);
    final canvasHeight = _number(template['height'], 700);
    final dpi = _number(template['dpi'], 96);
    final background = templateBytes == null
        ? null
        : pw.MemoryImage(Uint8List.fromList(templateBytes));
    final pageWidth = canvasWidth / dpi * 72;
    final pageHeight = canvasHeight / dpi * 72;
    final qr = _qrWidget(encodeVerificationQrPayload(record), 120);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            if (background != null)
              pw.Positioned.fill(
                child: pw.Image(background, fit: pw.BoxFit.fill),
              ),
            for (final field in fields)
              if (_fieldIsVisible(field))
                _pdfField(
                  values,
                  field,
                  canvasWidth,
                  canvasHeight,
                  pageWidth,
                  pageHeight,
                  font,
                ),
            pw.Positioned(
              left: 8,
              bottom: 6,
              child: pw.Text(hash, style: const pw.TextStyle(fontSize: 5)),
            ),
            pw.Positioned(right: 12, bottom: 12, child: qr),
          ],
        ),
      ),
    );
    final bytes = await document.save();
    return [...bytes, ...utf8.encode(_embeddedMarker(record))];
  }

  static List<int> renderPng({
    required Map<String, dynamic> values,
    required List<Map<String, Object?>> fields,
    required String hash,
    required Map<String, dynamic> record,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
  }) {
    final fallbackWidth = _number(template['width'], 1600).round();
    final fallbackHeight = _number(template['height'], 1100).round();
    var canvas = templateBytes == null
        ? img.Image(width: fallbackWidth, height: fallbackHeight)
        : img.decodeImage(Uint8List.fromList(templateBytes)) ??
              img.Image(width: fallbackWidth, height: fallbackHeight);
    final designWidth = _number(template['width'], canvas.width.toDouble());
    final designHeight = _number(template['height'], canvas.height.toDouble());
    // Upscale the actual source dimensions by one factor. Using the template
    // metadata here can stretch an image when its stored dimensions differ
    // from the decoded source image.
    const scale = 2;
    final targetWidth = canvas.width * scale;
    final targetHeight = canvas.height * scale;
    if (canvas.width != targetWidth || canvas.height != targetHeight) {
      canvas = img.copyResize(
        canvas,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );
    }
    if (templateBytes == null) {
      img.fill(canvas, color: img.ColorRgb8(250, 247, 240));
      img.drawRect(
        canvas,
        x1: 35,
        y1: 35,
        x2: canvas.width - 35,
        y2: canvas.height - 35,
        color: img.ColorRgb8(45, 93, 73),
        thickness: 8,
      );
    }
    for (final field in fields) {
      if (!_fieldIsVisible(field)) continue;
      final position = _jsonMap(field['position_json']);
      final style = _jsonMap(field['style_json']);
      final text = _fieldText(values, field);
      if (text.isEmpty) continue;
      final x = (_number(position['x'], 0) / designWidth * canvas.width)
          .round();
      final y = (_number(position['y'], 0) / designHeight * canvas.height)
          .round();
      img.drawString(
        canvas,
        text,
        font: _bitmapFont(_number(style['font_size'], 24)),
        x: x,
        y: y,
        color: _imageColor(style['color'] as String?),
      );
    }
    img.drawString(
      canvas,
      'Verification hash: $hash',
      font: img.arial14,
      x: 180,
      y: canvas.height - 40,
      color: img.ColorRgb8(90, 90, 90),
    );
    _drawQr(
      canvas,
      encodeVerificationQrPayload(record),
      x: canvas.width - _qrSize(canvas) - 32,
      y: canvas.height - _qrSize(canvas) - 32,
      size: _qrSize(canvas),
    );
    return [...img.encodePng(canvas), ...utf8.encode(_embeddedMarker(record))];
  }

  static int _qrSize(img.Image canvas) =>
      (math.min(canvas.width, canvas.height) * .24).round().clamp(220, 520);

  static pw.Widget _qrWidget(String payload, double size) {
    final matrix = Encoder.encode(payload, ErrorCorrectionLevel.l).matrix!;
    final count = matrix.width;
    const quietModules = 4;
    final module = size / (count + quietModules * 2);
    final totalSize = module * (count + quietModules * 2);
    return pw.Container(
      width: totalSize,
      height: totalSize,
      color: PdfColors.white,
      padding: pw.EdgeInsets.all(module * quietModules),
      child: pw.CustomPaint(
        size: PdfPoint(module * count, module * count),
        painter: (canvas, size) {
          canvas.setFillColor(PdfColors.black);
          for (var x = 0; x < count; x++) {
            for (var y = 0; y < count; y++) {
              if (matrix.get(x, y) == 1) {
                canvas.drawRect(
                  x * module,
                  size.y - (y + 1) * module,
                  module,
                  module,
                );
                canvas.fillPath();
              }
            }
          }
        },
      ),
    );
  }

  static void _drawQr(
    img.Image canvas,
    String payload, {
    required int x,
    required int y,
    required int size,
  }) {
    final matrix = Encoder.encode(payload, ErrorCorrectionLevel.l).matrix!;
    const quietModules = 4;
    final module = (size / (matrix.width + quietModules * 2)).floor().clamp(
      1,
      20,
    );
    final totalSize = (matrix.width + quietModules * 2) * module;
    final originX = x.clamp(0, canvas.width - totalSize);
    final originY = y.clamp(0, canvas.height - totalSize);
    img.fillRect(
      canvas,
      x1: originX,
      y1: originY,
      x2: originX + totalSize - 1,
      y2: originY + totalSize - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
    for (var row = 0; row < matrix.height; row++) {
      for (var col = 0; col < matrix.width; col++) {
        if (matrix.get(col, row) == 1) {
          final left = originX + (quietModules + col) * module;
          final top = originY + (quietModules + row) * module;
          img.fillRect(
            canvas,
            x1: left,
            y1: top,
            x2: left + module - 1,
            y2: top + module - 1,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }
  }

  static pw.Widget _pdfField(
    Map<String, dynamic> values,
    Map<String, Object?> field,
    double canvasWidth,
    double canvasHeight,
    double pageWidth,
    double pageHeight,
    pw.Font font,
  ) {
    final position = _jsonMap(field['position_json']);
    final style = _jsonMap(field['style_json']);
    final x = _number(position['x'], 0) / canvasWidth * pageWidth;
    final y = _number(position['y'], 0) / canvasHeight * pageHeight;
    final width = _number(position['width'], 420) / canvasWidth * pageWidth;
    final height = _number(position['height'], 64) / canvasHeight * pageHeight;
    final alignment = switch (style['alignment']) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.left,
    };
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Text(
          _fieldText(values, field),
          textAlign: alignment,
          style: pw.TextStyle(
            font: font,
            fontFallback: [font],
            fontSize: _number(style['font_size'], 24),
          ),
        ),
      ),
    );
  }

  static bool _fieldIsVisible(Map<String, Object?> field) =>
      _jsonMap(field['style_json'])['visible'] != false;

  static String _fieldText(
    Map<String, dynamic> values,
    Map<String, Object?> field,
  ) {
    final className = field['class_name'] as String?;
    final source = field['source'] as String?;
    final sourceValue = _valueForKey(values, source);
    if (sourceValue != null && '$sourceValue'.isNotEmpty) {
      return '$sourceValue';
    }
    final classValue = _valueForKey(values, className);
    return classValue == null ? '' : '$classValue';
  }

  static dynamic _valueForKey(Map<String, dynamic> values, String? key) {
    if (key == null) return null;
    final exact = values[key];
    if (exact != null) return exact;
    final normalizedKey = _normalizeKey(key);
    for (final entry in values.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) return entry.value;
    }
    return null;
  }

  static String _normalizeKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  static Map<String, dynamic> _jsonMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  static img.BitmapFont _bitmapFont(double size) {
    if (size >= 40) return img.arial48;
    if (size >= 28) return img.arial24;
    return img.arial14;
  }

  static img.Color _imageColor(String? value) {
    final hex = (value ?? '#20332B').replaceFirst('#', '');
    final normalized = hex.length == 6 ? hex : '20332B';
    return img.ColorRgb8(
      int.parse(normalized.substring(0, 2), radix: 16),
      int.parse(normalized.substring(2, 4), radix: 16),
      int.parse(normalized.substring(4, 6), radix: 16),
    );
  }

  static String _embeddedMarker(Map<String, dynamic> record) =>
      'CSTUDIO_RECORD_V1:${base64UrlEncodeNoPadding(utf8.encode(canonicalJson(record)))}';
}
