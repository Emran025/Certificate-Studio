import 'package:certificate_studio/config/localization/app_localizations.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:certificate_studio/features/data_import/presentation/widgets/data_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(ValueChanged<ImportedTable> onChanged, ImportedTable table) {
    var current = table;
    return MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: StatefulBuilder(
            builder: (context, setState) => DataPreview(
              table: current,
              disabled: false,
              onChanged: (next) {
                current = next;
                onChanged(next);
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpDesktop(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(child);
  }

  Finder actionButton(String tooltip) => find.byIcon(
    tooltip == 'Add field' ? Icons.add_box_outlined : Icons.person_add_alt_1,
  );

  Finder iconButton(String tooltip) => find.ancestor(
    of: actionButton(tooltip).last,
    matching: find.byType(IconButton),
  );

  testWidgets('Add field button creates a new empty column', (tester) async {
    var table = const ImportedTable(columns: ['name'], rows: []);
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add field').last);
    await tester.pumpAndSettle();
    expect(find.text('Field name'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'email');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.columns, ['name', 'email']);
    expect(find.text('email'), findsWidgets);
  });

  testWidgets('Add record row validates and saves all fields', (tester) async {
    var table = const ImportedTable(columns: ['name', 'grade'], rows: []);
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(actionButton('Add record row'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'Sara');
    await tester.enterText(fields.at(1), '95');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.rows, [
      {'name': 'Sara', 'grade': '95'},
    ]);
  });

  testWidgets('field rules dialog applies custom bounds and allowed values', (
    tester,
  ) async {
    var table = const ImportedTable(
      columns: ['grade', 'status'],
      rows: [
        {'grade': '88', 'status': 'pass'},
        {'grade': '91', 'status': 'fail'},
      ],
    );
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit field rules'));
    await tester.pumpAndSettle();
    expect(find.text('Field rules'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field-rule-min-grade')), '70');
    await tester.enterText(find.byKey(const Key('field-rule-max-grade')), '90');
    await tester.enterText(
      find.byKey(const Key('field-rule-choices-status')),
      'pass\nmerit',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.fieldRules.keys, containsAll(['grade', 'status']));
    expect(table.fieldRules['grade']?.min, 70);
    expect(table.fieldRules['grade']?.max, 90);
    expect(table.fieldRules['status']?.choices, ['pass', 'merit']);

    await tester.tap(actionButton('Add record row'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '95');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('Value must be between 70 and 90.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '85');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('merit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.rows.last, {'grade': '85', 'status': 'merit'});
  });

  testWidgets('field rules dialog saves rules for every project column', (
    tester,
  ) async {
    const columns = ['id', 'grade', 'status', 'hours', 'section', 'age'];
    var table = const ImportedTable(
      columns: columns,
      rows: [
        {
          'id': 'A001',
          'grade': '85',
          'status': 'pass',
          'hours': '3',
          'section': 'A',
          'age': '17',
        },
        {
          'id': 'A002',
          'grade': '92',
          'status': 'fail',
          'hours': '4',
          'section': 'B',
          'age': '18',
        },
      ],
    );
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit field rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.fieldRules.keys, containsAll(columns));
    expect(table.fieldRules.length, columns.length);
  });

  testWidgets('field rules dialog is optional and button fits a phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const table = ImportedTable(columns: ['name'], rows: []);
    await tester.pumpWidget(host((_) {}, table));
    await tester.pumpAndSettle();

    expect(find.text('Edit field rules'), findsOneWidget);
    expect(find.text('Field rules'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete field removes it from columns and every row', (
    tester,
  ) async {
    var table = const ImportedTable(
      columns: ['name', 'email'],
      rows: [
        {'name': 'Sara', 'email': 'sara@example.test'},
      ],
    );
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    final deleteButtons = find.byTooltip('Delete field');
    expect(deleteButtons, findsNWidgets(2));
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(table.columns, ['name']);
    expect(table.rows.single, {'name': 'Sara'});
  });

  testWidgets('Edit field renames its key without losing values', (
    tester,
  ) async {
    var table = const ImportedTable(
      columns: ['name'],
      rows: [
        {'name': 'Sara'},
      ],
    );
    await pumpDesktop(tester, host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit field').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'full name');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.columns, ['full name']);
    expect(table.rows.single, {'full name': 'Sara'});
  });

  testWidgets('disabled preview disables field and row action buttons', (
    tester,
  ) async {
    const table = ImportedTable(
      columns: ['name'],
      rows: [
        {'name': 'Sara'},
      ],
    );
    await pumpDesktop(
      tester,
      MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: DataPreview(table: table, disabled: true, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<IconButton>(iconButton('Add field')).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(iconButton('Add record row')).onPressed,
      isNull,
    );
    final rulesButton = find.ancestor(
      of: find.text('Edit field rules'),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(rulesButton).onPressed, isNull);
  });
}
