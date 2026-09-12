// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:certificate_studio/main.dart';
import 'package:certificate_studio/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Certificate Studio workspace', (tester) async {
    final database = InMemoryAppDatabase();
    await database.open();
    await tester.pumpWidget(CertificateStudioApp(database: database));
    await tester.pumpAndSettle();

    expect(find.text('Set up your institution'), findsOneWidget);
  });

  testWidgets('uses the light beige and green application theme', (tester) async {
    await tester.pumpWidget(const CertificateStudioApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.light);
    // expect(materialApp.theme?.fontFamily, 'Cairo');
  });
}
