import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production PDF embeds the shared Flutter canvas and QR verification', () {
    String readSource(String path) => File(path).readAsStringSync();

    final renderer = readSource(
      'lib/features/certificates/data/services/certificate_artifact_renderer.dart',
    );
    final service = readSource(
      'lib/features/certificates/data/services/certificate_generation_service.dart',
    );
    final designerCanvas = readSource(
      'lib/features/certificates/presentation/widgets/designer_canvas.dart',
    );
    final canvasWidget = readSource(
      'lib/features/certificates/presentation/widgets/certificate_canvas_visual.dart',
    );
    final generationScreen = readSource(
      'lib/features/certificates/presentation/screens/certificate_generation_screen/02_certificategenerationscreenstate.dart',
    );

    final rasterPdfStart = renderer.indexOf(
      'static Future<List<int>> renderPdfFromPng',
    );
    final embeddedRecordStart = renderer.indexOf(
      'static String _embeddedMarker',
      rasterPdfStart,
    );
    final rasterPdfRenderer = renderer.substring(
      rasterPdfStart,
      embeddedRecordStart,
    );

    expect(rasterPdfStart, isNonNegative);
    expect(rasterPdfRenderer, contains('pw.Image(image, fit: pw.BoxFit.fill)'));
    expect(rasterPdfRenderer, isNot(contains('pw.Text(')));
    expect(rasterPdfRenderer, contains('_embeddedMarker(record)'));
    expect(service, contains('canvasCapture != null'));
    expect(service, contains('preparePdfBackground('));
    expect(service, contains('targetPixelRatio: 300 / templateDpi'));
    expect(service, contains('await Isolate.run('));
    expect(service, contains('CertificateArtifactRenderer.redrawQrOnPng('));
    expect(
      service.indexOf('final captureBackgroundBytes') <
          service.indexOf('for (var index = 0; index < records.length; index++)'),
      isTrue,
    );
    expect(generationScreen, contains('canvasCapture: _captureCanvas'));
    expect(designerCanvas, contains('CertificateCanvasField('));
    expect(canvasWidget, contains('maxLines: 3'));
    expect(canvasWidget, contains('overflow: TextOverflow.clip'));
    expect(canvasWidget, contains('fontFamilyFallback: ['));
    expect(canvasWidget, contains('encodeVerificationQrPayload(record)'));
    expect(canvasWidget, contains('certificateCapturePixelRatio('));
    expect(canvasWidget, contains('minimumPixelsPerModule = 3.0'));
    expect(canvasWidget, contains('maxImageSide = 6000.0'));
    expect(renderer, isNot(contains('Verification hash:')));
  });
}
