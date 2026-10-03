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
          body: SingleChildScrollView(
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

  testWidgets('Add field button creates a new empty column', (tester) async {
    var table = const ImportedTable(columns: ['name'], rows: []);
    await tester.pumpWidget(host((next) => table = next, table));
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
    await tester.pumpWidget(host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add record row').last);
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

  testWidgets('Delete field removes it from columns and every row', (tester) async {
    var table = const ImportedTable(
      columns: ['name', 'email'],
      rows: [
        {'name': 'Sara', 'email': 'sara@example.test'},
      ],
    );
    await tester.pumpWidget(host((next) => table = next, table));
    await tester.pumpAndSettle();

    final deleteButtons = find.byTooltip('Delete field');
    expect(deleteButtons, findsNWidgets(2));
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(table.columns, ['name']);
    expect(table.rows.single, {'name': 'Sara'});
  });

  testWidgets('Edit field renames its key without losing values', (tester) async {
    var table = const ImportedTable(
      columns: ['name'],
      rows: [
        {'name': 'Sara'},
      ],
    );
    await tester.pumpWidget(host((next) => table = next, table));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit field').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'full name');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(table.columns, ['full name']);
    expect(table.rows.single, {'full name': 'Sara'});
  });

  testWidgets('disabled preview disables field and row action buttons', (tester) async {
    const table = ImportedTable(columns: ['name'], rows: [
      {'name': 'Sara'},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DataPreview(table: table, disabled: true, onChanged: (_) {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(find.byTooltip('Add field').last).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byTooltip('Add record row').last).onPressed, isNull);
  });
}
