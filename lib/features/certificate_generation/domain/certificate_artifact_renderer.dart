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
    required Map<String, List<int>> fontBytesByFamily,
  }) async {
    final document = pw.Document(title: 'Certificate');
    final fonts = <String, pw.Font>{
      for (final entry in fontBytesByFamily.entries)
        entry.key: pw.Font.ttf(
          ByteData.sublistView(Uint8List.fromList(entry.value)),
        ),
    };
    final defaultFont = fonts['Cairo'] ?? fonts.values.first;
    final canvasWidth = _number(template['width'], 1000);
    final canvasHeight = _number(template['height'], 700);
    final dpi = _number(template['dpi'], 96);
    final sourceImage = templateBytes == null
        ? null
        : img.decodeImage(Uint8List.fromList(templateBytes));
    final background = templateBytes == null
        ? null
        : pw.MemoryImage(Uint8List.fromList(templateBytes));
    // The designer stores the logical canvas size separately from the actual
    // image dimensions. Use the image aspect ratio for the PDF page so the
    // background and the positioned fields share the same visible surface.
    final outputWidth = sourceImage?.width.toDouble() ?? canvasWidth;
    final outputHeight = sourceImage?.height.toDouble() ?? canvasHeight;
    final pageWidth = outputWidth / dpi * 72;
    final pageHeight = outputHeight / dpi * 72;
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
                child: pw.Image(background, fit: pw.BoxFit.fill),
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
                  fonts,
                  defaultFont,
                  pageWidth / canvasWidth,
                ),
            pw.Positioned(
              left: 8,
              bottom: 6,
              child: pw.Text(
                hash,
                style: pw.TextStyle(
                  font: defaultFont,
                  fontFallback: fonts.values.toList(),
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

  static List<int> renderPng({
    required Map<String, dynamic> values,
    required List<Map<String, Object?>> fields,
    required String hash,
    required Map<String, dynamic> record,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
  }) {
    final designWidth = _number(template['width'], 1600);
    final designHeight = _number(template['height'], 1100);
    final logicalWidth = designWidth.round();
    final logicalHeight = designHeight.round();
    var canvas = img.Image(width: logicalWidth, height: logicalHeight);
    img.fill(canvas, color: img.ColorRgb8(250, 247, 240));
    final source = templateBytes == null
        ? null
        : img.decodeImage(Uint8List.fromList(templateBytes));
    if (source != null) {
      // Match the designer's BoxFit.contain behavior. The background is
      // centered inside the logical design canvas instead of being stretched
      // to the source image's raw pixel dimensions.
      final fitScale = math.min(
        logicalWidth / source.width,
        logicalHeight / source.height,
      );
      final fittedWidth = (source.width * fitScale).round();
      final fittedHeight = (source.height * fitScale).round();
      final fitted = img.copyResize(
        source,
        width: fittedWidth,
        height: fittedHeight,
        interpolation: img.Interpolation.cubic,
      );
      img.compositeImage(
        canvas,
        fitted,
        dstX: ((logicalWidth - fittedWidth) / 2).round(),
        dstY: ((logicalHeight - fittedHeight) / 2).round(),
      );
    }
    if (templateBytes == null) {
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
    // Render every element in the same logical coordinate space used by the
    // designer, then upscale the complete result without changing geometry.
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
    final logicalScale = canvas.width / logicalWidth;
    for (final field in fields) {
      if (!_fieldIsVisible(field) || _isQrField(field)) continue;
      final position = _jsonMap(field['position_json']);
      final style = _jsonMap(field['style_json']);
      final text = _fieldText(values, field);
      if (text.isEmpty) continue;
      final x = (_number(position['x'], 0) * logicalScale).round();
      final y = (_number(position['y'], 0) * logicalScale).round();
      img.drawString(
        canvas,
        text,
        font: _bitmapFont(_number(style['font_size'], 24) * logicalScale),
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
    final qrFields = fields.where(_isQrField);
    final qrField = qrFields.isEmpty ? null : qrFields.first;
    final qrPosition = qrField == null
        ? <String, dynamic>{}
        : _jsonMap(qrField['position_json']);
    final qrLogicalSize = _number(qrPosition['width'], 220);
    final qrSize = (qrLogicalSize * logicalScale)
        .clamp(120, math.min(canvas.width, canvas.height))
        .round();
    final qrX = qrField == null
        ? canvas.width - qrSize - 32
        : (_number(qrPosition['x'], 0) * logicalScale).round();
    final qrY = qrField == null
        ? canvas.height - qrSize - 32
        : (_number(qrPosition['y'], 0) * logicalScale).round();
    _drawQr(canvas, encodeVerificationQrPayload(record), x: qrX, y: qrY, size: qrSize);
    return [...img.encodePng(canvas), ...utf8.encode(_embeddedMarker(record))];
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
      width: width,
      height: height,
      child: pw.Center(
        child: _qrWidget(payload, math.min(width, height)),
      ),
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
    Map<String, pw.Font> fonts,
    pw.Font defaultFont,
    double canvasToPdfScale,
  ) {
    final position = _jsonMap(field['position_json']);
    final style = _jsonMap(field['style_json']);
    final font = fonts[style['font_family']?.toString()] ?? defaultFont;
    final x = _number(position['x'], 0) / canvasWidth * pageWidth;
    final y = _number(position['y'], 0) / canvasHeight * pageHeight;
    final width = _number(position['width'], 420) / canvasWidth * pageWidth;
    final height = _number(position['height'], 64) / canvasHeight * pageHeight;
    final alignment = switch (style['alignment']) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.left,
    };
    final boxAlignment = switch (style['alignment']) {
      'center' => pw.Alignment.center,
      'right' => pw.Alignment.centerRight,
      _ => pw.Alignment.centerLeft,
    };
    final direction = style['direction'] == 'rtl'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    final textStyle = pw.TextStyle(
      color: _pdfColor(style['color'] as String?),
      font: font,
      fontFallback: fonts.values.where((item) => item != font).toList(),
      fontSize: _number(style['font_size'], 24) * canvasToPdfScale,
    );
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
          child: pw.Align(
            alignment: boxAlignment,
            child: pw.Directionality(
              textDirection: direction,
              child: pw.Text(
                _fieldText(values, field),
                textAlign: alignment,
                style: textStyle,
              ),
            ),
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

  static PdfColor _pdfColor(String? value) {
    final raw = value?.replaceFirst('#', '');
    if (raw == null || (raw.length != 6 && raw.length != 8)) {
      return PdfColors.black;
    }
    final parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) return PdfColors.black;
    final rgb = raw.length == 8 ? parsed & 0xFFFFFF : parsed;
    final alpha = raw.length == 8 ? ((parsed >> 24) & 0xFF) / 255 : 1.0;
    return PdfColor(
      ((rgb >> 16) & 0xFF) / 255,
      ((rgb >> 8) & 0xFF) / 255,
      (rgb & 0xFF) / 255,
      alpha,
    );
  }

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
