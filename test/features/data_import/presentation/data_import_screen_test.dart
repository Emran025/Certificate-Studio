import 'dart:convert';

import 'package:certificate_studio/config/localization/app_localizations.dart';
import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/features/data_import/presentation/screens/data_import_screen.dart';
import 'package:certificate_studio/features/data_import/presentation/widgets/data_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _timestamp = '2026-11-01T00:00:00Z';

Future<InMemoryAppDatabase> _existingProjectWithRows(
  List<Map<String, Object?>> records,
) async {
  final database = InMemoryAppDatabase();
  await database.open();
  await database.insert(DatabaseTables.projects, {
    'id': 'project-1',
    'institution_id': 'institution-1',
    'name': 'Existing project',
    'project_key_reference': 'project-key',
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
  for (var index = 0; index < records.length; index++) {
    await database.insert(DatabaseTables.records, {
      'id': 'record-$index',
      'project_id': 'project-1',
      'class_name': 'A001',
      'data_json': records[index]['data_json'],
      if (records[index].containsKey('columns_json'))
        'columns_json': records[index]['columns_json'],
      'row_number': index + 1,
      'created_at': _timestamp,
      'updated_at': _timestamp,
    });
  }
  return database;
}

Future<void> _openImportScreen(
  WidgetTester tester,
  InMemoryAppDatabase database,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: AppLocalizations.supportedLocales,
      home: DataImportScreen(database: database, projectId: 'project-1'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens existing project rows saved without column metadata', (
    tester,
  ) async {
    final database = await _existingProjectWithRows([
      {'data_json': '{"name":"Ahmed Ali","grade":"95"}'},
      {'data_json': '{"name":"Sara","grade":"91"}'},
    ]);
    addTearDown(() => database.close());

    await _openImportScreen(tester, database);

    expect(tester.takeException(), isNull);
    expect(
      find.text('Unsupported operation: Cannot add to an unmodifiable list'),
      findsNothing,
    );
    expect(find.byType(DataPreview), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
  });

  testWidgets(
    'opens existing project rows with per-row columns but no project column setting',
    (tester) async {
      final database = await _existingProjectWithRows([
        {
          'data_json': '{"name":"Ahmed Ali","grade":"95"}',
          'columns_json': '["name","grade"]',
        },
      ]);
      addTearDown(() => database.close());

      await _openImportScreen(tester, database);

      expect(
        find.text('Unsupported operation: Cannot add to an unmodifiable list'),
        findsNothing,
      );
      expect(find.byType(DataPreview), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
    },
  );

  testWidgets('field rules dialog saves through the feature BLoC', (
    tester,
  ) async {
    final database = await _existingProjectWithRows([
      {'data_json': '{"grade":"85"}'},
    ]);
    addTearDown(database.close);

    await _openImportScreen(tester, database);
    await tester.tap(find.text('Edit field rules'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-rule-min-grade')), '70');
    await tester.enterText(find.byKey(const Key('field-rule-max-grade')), '90');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final storedSettings = await database.query(
      DatabaseTables.settings,
      where: {'key': 'records-field-rules:project-1'},
      columns: ['value_json'],
    );
    expect(storedSettings, hasLength(1));
    final storedRules =
        jsonDecode(storedSettings.single['value_json']! as String)
            as Map<String, dynamic>;
    final gradeRule = storedRules['grade'] as Map<String, dynamic>;
    expect(gradeRule['kind'], 'number');
    expect(gradeRule['min'], 70.0);
    expect(gradeRule['max'], 90.0);
  });
}
