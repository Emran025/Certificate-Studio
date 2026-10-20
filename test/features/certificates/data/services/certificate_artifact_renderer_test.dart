import 'dart:convert';
import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_artifact_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test(
    'only enhances the background when its source resolution is insufficient',
    () {
      final source = img.Image(width: 20, height: 10);
      img.fill(source, color: img.ColorRgb8(220, 180, 40));
      final sourceBytes = img.encodePng(source);

      final prepared = CertificateArtifactRenderer.preparePdfBackground(
        sourceBytes,
        targetPixelRatio: 3,
        canvasWidth: 20,
        canvasHeight: 10,
      );
      final decoded = img.decodeImage(Uint8List.fromList(prepared!));

      expect(decoded?.width, 60);
      expect(decoded?.height, 30);

      final alreadySharp = img.Image(width: 60, height: 30);
      img.fill(alreadySharp, color: img.ColorRgb8(220, 180, 40));
      final originalBytes = img.encodePng(alreadySharp);
      expect(
        CertificateArtifactRenderer.preparePdfBackground(
          originalBytes,
          targetPixelRatio: 3,
          canvasWidth: 20,
          canvasHeight: 10,
        ),
        same(originalBytes),
      );
    },
  );

  test('raster PDF preserves its embedded signed verification record', () async {
    final canvas = img.Image(width: 4, height: 3);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    final record = <String, dynamic>{
      'certificate_id': 'certificate-123',
      'signature': 'signed-payload',
      'fields': {'recipient': 'سارة أحمد'},
    };

    final pdfBytes = await CertificateArtifactRenderer.renderPdfFromPng(
      imageBytes: img.encodePng(canvas),
      record: record,
      template: {'width': 4, 'height': 3, 'dpi': 72},
    );
    final pdfText = latin1.decode(pdfBytes);
    final marker =
        'CSTUDIO_RECORD_V1:${base64UrlEncodeNoPadding(utf8.encode(canonicalJson(record)))}';

    expect(pdfText, startsWith('%PDF-'));
    expect(pdfText, endsWith(marker));
    expect(pdfText, isNot(contains('Verification hash:')));
  });
}
