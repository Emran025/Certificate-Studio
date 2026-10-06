import 'package:certificate_studio/features/settings/data/services/workspace_transfer_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes records with a stable union of columns', () {
    final csv = recordsToCsv([
      {'data_json': '{"name":"Sara","course":"Flutter"}'},
      {'data_json': '{"name":"Omar","note":"A, B"}'},
    ]);

    expect(csv, 'name,course,note\r\nSara,Flutter,\r\nOmar,,"A, B"');
  });

  test('parses quoted commas, escaped quotes, and missing cells', () {
    final rows = csvToRows(
      'name,note,city\r\nSara,"A, ""great"" course",\r\nOmar,,Amman',
    );

    expect(rows, [
      {'name': 'Sara', 'note': 'A, "great" course', 'city': ''},
      {'name': 'Omar', 'note': '', 'city': 'Amman'},
    ]);
  });

  test('returns no rows for an empty document', () {
    expect(csvToRows(''), isEmpty);
    expect(csvToRows('\r\n'), isEmpty);
  });
}
