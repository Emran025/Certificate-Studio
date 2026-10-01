import '../../domain/entities/imported_table.dart';

enum DataImportStatus { initial, loading, saving, loaded, failure }

class DataImportState {
  const DataImportState({
    this.status = DataImportStatus.initial,
    this.table = const ImportedTable(columns: [], rows: []),
    this.errorMessage,
  });

  final DataImportStatus status;
  final ImportedTable table;
  final String? errorMessage;

  bool get isSaving => status == DataImportStatus.saving;
}
