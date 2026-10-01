import 'dart:typed_data';
import '../../domain/entities/imported_table.dart';

sealed class DataImportEvent {
  const DataImportEvent();
}

final class DataImportRequested extends DataImportEvent {
  const DataImportRequested();
}

final class PasteTableRequested extends DataImportEvent {
  const PasteTableRequested(this.rawText);

  final String rawText;
}

final class ExcelImportRequested extends DataImportEvent {
  const ExcelImportRequested(this.bytes);

  final Uint8List bytes;
}

final class TableUpdatedRequested extends DataImportEvent {
  const TableUpdatedRequested(this.table);

  final ImportedTable table;
}

final class DataImportErrorReported extends DataImportEvent {
  const DataImportErrorReported(this.message);

  final String message;
}
