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
  });
}
