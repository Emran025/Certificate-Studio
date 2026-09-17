import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';

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

class DataImportBloc extends Bloc<DataImportEvent, DataImportState> {
  DataImportBloc({
    required this._projectId,
    required this._pasteTable,
    required this._importExcel,
    required this._loadTable,
    required this._saveTable,
  }) : super(const DataImportState()) {
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
