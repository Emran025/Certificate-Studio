import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:certificate_studio/features/certificates/presentation/widgets/certificate_canvas_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('renders Arabic text and QR on the template-sized canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CertificateCanvasExportView(
            values: {'recipient': 'سارة أحمد'},
            fields: [
              {
                'class_name': 'recipient',
                'source': 'recipient',
                'position_json': jsonEncode({
                  'x': 20,
                  'y': 20,
                  'width': 240,
                  'height': 60,
                }),
                'style_json': jsonEncode({
                  'kind': 'text',
                  'font_family': 'Cairo',
                  'font_size': 28,
                  'color': '#20332B',
                  'alignment': 'center',
                  'direction': 'rtl',
                }),
              },
              {
                'class_name': 'verification_qr',
                'source': '',
                'position_json': jsonEncode({
                  'x': 300,
                  'y': 20,
                  'width': 80,
                  'height': 80,
                }),
                'style_json': jsonEncode({'kind': 'qr'}),
              },
            ],
            record: {'certificate_id': 'test-certificate'},
            templateBytes: _backgroundPng(),
            template: {'width': 400, 'height': 200, 'dpi': 96},
            fontFamilies: const ['Cairo'],
          ),
        ),
      ),
    );

    final canvasFinder = find.byType(CertificateCanvasExportView);
    expect(tester.getSize(canvasFinder), const Size(400, 200));
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    expect(
      tester.widget<Text>(find.text('سارة أحمد')).style?.decoration,
      TextDecoration.none,
    );

    final fields = tester
        .widgetList<CertificateCanvasField>(find.byType(CertificateCanvasField))
        .toList();
    expect(fields, hasLength(2));
    expect(fields.first.text, 'سارة أحمد');
    expect(fields.first.direction, TextDirection.rtl);
    expect(fields.last.qr, isTrue);
    expect(fields.last.qrPayload, contains('cstudio://verify/'));
    expect(find.byType(CertificateQrCode), findsOneWidget);

    final textPosition = tester.widget<Positioned>(
      find.ancestor(
        of: find.text('سارة أحمد'),
        matching: find.byType(Positioned),
      ),
    );
    expect(textPosition.left, 20);
    expect(textPosition.top, 20);
    expect(textPosition.width, 240);
    expect(textPosition.height, 60);
    expect(
      certificateCanvasText(
        values: {'Recipient Name': 'Sara'},
        source: 'recipient-name',
      ),
      'Sara',
    );
    expect(
      certificateCanvasText(values: const {}, source: 'recipient'),
      'recipient',
    );
    expect(
      certificateCanvasText(values: {'recipient': ''}, source: 'recipient'),
      '',
    );
    expect(
      certificateCanvasText(
        values: const {},
        source: 'recipient',
        staticText: 'Explicit label',
      ),
      'Explicit label',
    );
  });

  testWidgets('legacy field renderer remains available on the same interface', (
    tester,
  ) async {
    const field = CertificateCanvasField(
      text: 'legacy QR preview',
      fontFamily: 'Cairo',
      fontFamilies: ['Cairo'],
      fontSize: 28,
      color: '#20332B',
      alignment: 'left',
      direction: TextDirection.ltr,
      bold: false,
      italic: false,
      qr: true,
    );
    final legacy = const LegacyCertificateCanvasFieldRenderer().render(field);

    await tester.pumpWidget(MaterialApp(home: Center(child: legacy)));

    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    expect(find.byType(CertificateQrCode), findsNothing);
    expect(
      const LegacyCertificateCanvasFieldRenderer(),
      isA<CertificateCanvasFieldRenderer>(),
    );
    expect(
      const FlutterCertificateCanvasFieldRenderer(),
      isA<CertificateCanvasFieldRenderer>(),
    );
  });

  testWidgets('uses the decoded background image for deterministic capture', (
    tester,
  ) async {
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(_backgroundPng()),
    );
    final background = (await codec.getNextFrame()).image;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CertificateCanvasExportView(
            values: const {},
            fields: const [],
            record: const {},
            templateBytes: null,
            template: const {'width': 400, 'height': 200, 'dpi': 96},
            fontFamilies: const ['Cairo'],
            backgroundImage: background,
          ),
        ),
      ),
    );

    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).fit, BoxFit.contain);
    await tester.pumpWidget(const SizedBox.shrink());
    background.dispose();
    codec.dispose();
  });
}

List<int> _backgroundPng() {
  final image = img.Image(width: 2, height: 2);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  return img.encodePng(image);
}
