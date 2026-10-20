import 'dart:convert';

import 'package:certificate_studio/features/certificates/presentation/widgets/certificate_canvas_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            templateBytes: null,
            template: {'width': 400, 'height': 200, 'dpi': 96},
            fontFamilies: const ['Cairo'],
          ),
        ),
      ),
    );

    final canvasFinder = find.byType(CertificateCanvasExportView);
    expect(tester.getSize(canvasFinder), const Size(400, 200));
    expect(find.text('سارة أحمد'), findsOneWidget);

    final fields = tester
        .widgetList<CertificateCanvasField>(find.byType(CertificateCanvasField))
        .toList();
    expect(fields, hasLength(2));
    expect(fields.first.text, 'سارة أحمد');
    expect(fields.first.direction, TextDirection.rtl);
    expect(fields.last.qr, isTrue);
    expect(fields.last.qrPayload, contains('cstudio://verify/'));

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
}
