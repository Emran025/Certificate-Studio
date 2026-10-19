import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production preserves the designer canvas and QR-only verification', () {
    final renderer = File(
      'lib/features/certificates/data/services/certificate_artifact_renderer.dart',
    ).readAsStringSync();
    final designerCanvas = File(
      'lib/features/certificates/presentation/widgets/designer_canvas.dart',
    ).readAsStringSync();

    expect(renderer, contains('final pageWidth = canvasWidth / dpi * 72;'));
    expect(renderer, contains('final pageHeight = canvasHeight / dpi * 72;'));
    expect(renderer, contains('pw.Image(background, fit: pw.BoxFit.contain)'));
    expect(
      renderer,
      contains('_number(position[\'x\'], 0) / canvasWidth * pageWidth'),
    );
    expect(renderer, contains('maxLines: 3'));
    expect(renderer, contains('overflow: pw.TextOverflow.clip'));
    expect(designerCanvas, contains('maxLines: 3'));
    expect(designerCanvas, contains('overflow: TextOverflow.clip'));

    expect(renderer, isNot(contains('Verification hash:')));
    expect(renderer, contains('encodeVerificationQrPayload(record)'));
    expect(renderer, contains('_embeddedMarker(record)'));
  });
}
