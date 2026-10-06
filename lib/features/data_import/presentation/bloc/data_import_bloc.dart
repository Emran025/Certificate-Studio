// ignore_for_file: prefer_initializing_formals

export 'data_import_event.dart';
export 'data_import_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'data_import_event.dart';
import 'data_import_state.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';

class DataImportBloc extends Bloc<DataImportEvent, DataImportState> {
  DataImportBloc({
    required String projectId,
    required PasteTable pasteTable,
    required ImportExcel importExcel,
    required Future<ImportedTable> Function() loadTable,
    required Future<ImportedTable> Function(ImportedTable table) saveTable,
  }) : _projectId = projectId,
       _pasteTable = pasteTable,
       _importExcel = importExcel,
       _loadTable = loadTable,
       _saveTable = saveTable,
       super(const DataImportState()) {
    on<DataImportRequested>(_onLoad);
    on<PasteTableRequested>(_onPaste);
    on<ExcelImportRequested>(_onExcel);
    on<TableUpdatedRequested>(_onTableUpdated);
    on<DataImportErrorReported>(
      (event, emit) => emit(
        DataImportState(
          status: DataImportStatus.failure,
          table: state.table,
          errorMessage: event.message,
        ),
      ),
    );
  }

  final PasteTable _pasteTable;
  final ImportExcel _importExcel;
  final Future<ImportedTable> Function() _loadTable;
  final Future<ImportedTable> Function(ImportedTable table) _saveTable;

  Future<void> _onLoad(
    DataImportRequested event,
    Emitter<DataImportState> emit,
  ) async {
    emit(DataImportState(status: DataImportStatus.loading, table: state.table));
    try {
      emit(
        DataImportState(
          status: DataImportStatus.loaded,
          table: await _loadTable(),
        ),
      );
    } catch (error) {
      emit(
        DataImportState(
          status: DataImportStatus.failure,
          table: state.table,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPaste(
    PasteTableRequested event,
    Emitter<DataImportState> emit,
  ) async {
    await _save(
      emit,
      () => _pasteTable(projectId: _projectId, rawText: event.rawText),
    );
  }

  Future<void> _onExcel(
    ExcelImportRequested event,
    Emitter<DataImportState> emit,
  ) async {
    await _save(
      emit,
      () => _importExcel(projectId: _projectId, bytes: event.bytes),
    );
  }

  Future<void> _onTableUpdated(
    TableUpdatedRequested event,
    Emitter<DataImportState> emit,
  ) async {
    await _save(emit, () => _saveTable(event.table));
  }

  final String _projectId;

  Future<void> _save(
    Emitter<DataImportState> emit,
    Future<ImportedTable> Function() action,
  ) async {
    emit(DataImportState(status: DataImportStatus.saving, table: state.table));
    try {
      emit(
        DataImportState(status: DataImportStatus.loaded, table: await action()),
      );
    } on FormatException catch (error) {
      emit(
        DataImportState(
          status: DataImportStatus.failure,
          table: state.table,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        DataImportState(
          status: DataImportStatus.failure,
          table: state.table,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
