import 'package:certificate_studio/features/data_import/domain/entities/import_merge_plan.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects exact duplicates by normalized name and class', () {
    const existing = ImportedTable(
      columns: ['Name', 'Class', 'Grade'],
      rows: [
        {'Name': 'Ahmed Ali', 'Class': 'A', 'Grade': '95'},
      ],
      recordIds: ['record-1'],
    );
    const incoming = ImportedTable(
      columns: ['name', 'class', 'grade'],
      rows: [
        {'name': ' ahmed ali ', 'class': 'a', 'grade': '95'},
      ],
    );

    final plan = ImportMergePlanner.plan(
      existing: existing,
      incoming: incoming,
    );

    expect(plan.conflicts, hasLength(1));
    expect(plan.conflicts.single.exactDuplicate, isTrue);
    expect(plan.newRowCount, 0);
  });

  test(
    'detects same identity with changed values and replaces the selected row',
    () {
      const existing = ImportedTable(
        columns: ['Name', 'Grade'],
        rows: [
          {'Name': 'Sara', 'Grade': '80'},
        ],
        recordIds: ['record-1'],
      );
      const incoming = ImportedTable(
        columns: ['name', 'grade'],
        rows: [
          {'name': 'Sara', 'grade': '95'},
        ],
      );

      final plan = ImportMergePlanner.plan(
        existing: existing,
        incoming: incoming,
      );
      final merged = plan.apply({0: ImportMergeDecision.useImported});

      expect(plan.conflicts.single.exactDuplicate, isFalse);
      expect(merged.rows, [
        {'Name': 'Sara', 'Grade': '95'},
      ]);
      expect(merged.recordIds, ['record-1']);
    },
  );

  test('keeps both rows without losing existing record identity', () {
    const existing = ImportedTable(
      columns: ['Name', 'Grade'],
      rows: [
        {'Name': 'Sara', 'Grade': '80'},
      ],
      recordIds: ['record-1'],
    );
    const incoming = ImportedTable(
      columns: ['name', 'grade'],
      rows: [
        {'name': 'Sara', 'grade': '95'},
      ],
    );

    final plan = ImportMergePlanner.plan(
      existing: existing,
      incoming: incoming,
    );
    final merged = plan.apply({0: ImportMergeDecision.keepBoth});

    expect(merged.rows, [
      {'Name': 'Sara', 'Grade': '80'},
      {'Name': 'Sara', 'Grade': '95'},
    ]);
    expect(merged.recordIds, ['record-1', null]);
  });

  test('adds new columns and rows while reusing matching columns', () {
    const existing = ImportedTable(
      columns: ['Name', 'Grade'],
      rows: [
        {'Name': 'Ahmed', 'Grade': '90'},
      ],
      recordIds: ['record-1'],
    );
    const incoming = ImportedTable(
      columns: ['name', 'School'],
      rows: [
        {'name': 'Mona', 'School': 'North'},
      ],
    );

    final plan = ImportMergePlanner.plan(
      existing: existing,
      incoming: incoming,
    );
    final merged = plan.apply(const {});

    expect(plan.newColumnCount, 1);
    expect(plan.reusedColumnCount, 1);
    expect(merged.columns, ['Name', 'Grade', 'School']);
    expect(merged.rows, [
      {'Name': 'Ahmed', 'Grade': '90', 'School': ''},
      {'Name': 'Mona', 'Grade': '', 'School': 'North'},
    ]);
  });
}
