import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_artifact_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
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
