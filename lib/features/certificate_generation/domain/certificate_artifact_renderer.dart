import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
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
    final qrField = fields.where(_isQrField).isEmpty
        ? null
        : fields.where(_isQrField).first;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            if (background != null)
              pw.Positioned.fill(
                child: pw.Image(background, fit: pw.BoxFit.contain),
              ),
            for (final field in fields)
              if (_fieldIsVisible(field) && !_isQrField(field))
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
              child: pw.Text(
                hash,
                style: pw.TextStyle(
                  font: font,
                  fontFallback: [font],
                  fontSize: 5,
                ),
              ),
            ),
            _pdfQrField(
              encodeVerificationQrPayload(record),
              qrField,
              canvasWidth,
              canvasHeight,
              pageWidth,
              pageHeight,
            ),
          ],
        ),
      ),
    );
    final bytes = await document.save();
    return [...bytes, ...utf8.encode(_embeddedMarker(record))];
  }

  static bool _isQrField(Map<String, Object?> field) =>
      _jsonMap(field['style_json'])['kind'] == 'qr';

  static pw.Widget _pdfQrField(
    String payload,
    Map<String, Object?>? field,
    double canvasWidth,
    double canvasHeight,
    double pageWidth,
    double pageHeight,
  ) {
    if (field == null) {
      return pw.Positioned(right: 12, bottom: 12, child: _qrWidget(payload, 120));
    }
    final position = _jsonMap(field['position_json']);
    final x = _number(position['x'], 0) / canvasWidth * pageWidth;
    final y = _number(position['y'], 0) / canvasHeight * pageHeight;
    final width = _number(position['width'], 220) / canvasWidth * pageWidth;
    final height = _number(position['height'], 220) / canvasHeight * pageHeight;
    return pw.Positioned(
      left: x,
      top: y,
      child: _qrWidget(payload, math.min(width, height)),
    );
  }

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

  static String _normalizeKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static Map<String, dynamic> _jsonMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  static String _embeddedMarker(Map<String, dynamic> record) =>
      'CSTUDIO_RECORD_V1:${base64UrlEncodeNoPadding(utf8.encode(canonicalJson(record)))}';
}
