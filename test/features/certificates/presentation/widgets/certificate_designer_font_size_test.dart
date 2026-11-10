import 'dart:convert';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/features/certificates/presentation/screens/certificate_designer_screen.dart';
import 'package:certificate_studio/features/certificates/presentation/widgets/certificate_canvas_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'updates font size while editing and allows large certificate text',
    (tester) async {
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

      await tester.tap(find.text('Aisha'));
      await tester.pump();
      await tester.tap(find.byTooltip('Field properties'));
      await tester.pumpAndSettle();
      final fontSizeInput = find.byKey(const ValueKey('name-field-font-size'));
      await tester.ensureVisible(fontSizeInput);

      await tester.enterText(fontSizeInput, '260');
      await tester.pump();

      final canvasField = find.byWidgetPredicate(
        (widget) => widget is CertificateCanvasField && widget.text == 'Aisha',
      );
      expect(canvasField, findsOneWidget);
      expect(tester.widget<CertificateCanvasField>(canvasField).fontSize, 260);

      await tester.enterText(fontSizeInput, '600');
      await tester.pump();
      expect(tester.widget<CertificateCanvasField>(canvasField).fontSize, 512);

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      final fontTextField = find.descendant(
        of: fontSizeInput,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(fontTextField).controller?.text, '512');
    },
  );
}
