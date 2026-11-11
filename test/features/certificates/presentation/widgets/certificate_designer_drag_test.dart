import 'dart:convert';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/features/certificates/presentation/screens/certificate_designer_screen.dart';
import 'package:certificate_studio/features/certificates/presentation/widgets/certificate_canvas_visual.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dragging a field follows the pointer at reduced canvas zoom', (
    tester,
  ) async {
    final database = InMemoryAppDatabase();
    await database.open();
    final now = DateTime.utc(2026, 11, 10).toIso8601String();
    await database.insert(DatabaseTables.projects, {
      'id': 'project-1',
      'institution_id': 'institution-1',
      'name': 'Demo project',
      'template_id': 'template-1',
      'settings_json': '{}',
      'project_key_reference': 'key-1',
      'created_at': now,
      'updated_at': now,
    });
    await database.insert(DatabaseTables.templates, {
      'id': 'template-1',
      'name': 'Demo template',
      'file_path': 'missing-template.png',
      'width': 1600,
      'height': 1100,
      'dpi': 96,
      'format': 'png',
      'created_at': now,
      'updated_at': now,
    });
    await database.insert(DatabaseTables.records, {
      'id': 'record-1',
      'project_id': 'project-1',
      'class_name': 'student',
      'data_json': jsonEncode({'recipient_name': 'Aisha'}),
      'row_number': 1,
      'created_at': now,
      'updated_at': now,
    });
    await database.insert(DatabaseTables.certificateFields, {
      'id': 'name-field',
      'project_id': 'project-1',
      'class_name': 'recipient_name',
      'source': 'recipient_name',
      'position_json': jsonEncode({
        'x': 200,
        'y': 200,
        'width': 500,
        'height': 100,
      }),
      'style_json': jsonEncode({
        'kind': 'text',
        'font_size': 28,
        'font_family': 'Cairo',
        'color': '#20332B',
        'alignment': 'left',
        'direction': 'ltr',
      }),
      'created_at': now,
      'updated_at': now,
    });

    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      await database.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CertificateDesignerScreen(
          database: database,
          projectId: 'project-1',
          projectName: 'Demo project',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byWidgetPredicate(
      (widget) => widget is CertificateCanvasField && widget.text == 'Aisha',
    );
    expect(field, findsOneWidget);
    final before = tester.getCenter(field);
    const pointerDelta = Offset(60, 32);

    final gesture = await tester.startGesture(
      before,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(pointerDelta);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final after = tester.getCenter(field);
    expect(after.dx - before.dx, closeTo(pointerDelta.dx, 1));
    expect(after.dy - before.dy, closeTo(pointerDelta.dy, 1));
  });
}
