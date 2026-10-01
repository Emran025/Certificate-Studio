part of '../data_preview.dart';

class DataPreview extends StatelessWidget {
  const DataPreview({
    super.key,
    required this.table,
    required this.disabled,
    required this.onChanged,
  });

  final ImportedTable table;
  final bool disabled;
  final ValueChanged<ImportedTable> onChanged;

  Map<String, _FieldProfile> get _profiles => {
    for (var index = 0; index < table.columns.length; index++)
      table.columns[index]: _profileFor(table.columns[index], index),
  };

  _FieldProfile _profileFor(String column, int columnIndex) {
    if (columnIndex == 0 && _isIdentifierColumn(column)) {
      return const _FieldProfile(kind: _FieldKind.text);
    }

    final values = table.rows
        .map((row) => row[column]?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
    final numbers = values.map(double.tryParse).toList();
    if (values.isNotEmpty && numbers.every((value) => value != null)) {
      final numericValues = numbers.cast<double>();
      final observedMin = numericValues.reduce((a, b) => a < b ? a : b);
      final observedMax = numericValues.reduce((a, b) => a > b ? a : b);
      final scaleMax = observedMax <= 5
          ? 5.0
          : observedMax <= 10
          ? 10.0
          : observedMax <= 100
          ? 100.0
          : observedMax;
      return _FieldProfile(
        kind: _FieldKind.number,
        min: observedMin < 0 ? observedMin : 0,
        max: scaleMax < observedMax ? observedMax : scaleMax,
      );
    }
    final unique = values.toSet().toList();
    if (unique.length <= 8 ||
        (values.isNotEmpty && unique.length / values.length <= .35)) {
      return _FieldProfile(kind: _FieldKind.choice, choices: unique);
    }
    return const _FieldProfile(kind: _FieldKind.text);
  }

  bool _isIdentifierColumn(String column) {
    final normalized = column.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    );
    return normalized == 'م' ||
        normalized.contains('رقم') ||
        normalized.contains('معرف') ||
        normalized == 'id' ||
        normalized.contains('identifier') ||
        normalized.contains('number');
  }

  Future<void> _editRow(BuildContext context, int? rowIndex) async {
    final initial = rowIndex == null
        ? {for (final column in table.columns) column: ''}
        : {...table.rows[rowIndex]};
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _RecordEditor(
        columns: table.columns,
        profiles: _profiles,
        initialValues: initial,
      ),
    );
    if (!context.mounted || values == null) return;
    final rows = [...table.rows];
    if (rowIndex == null) {
      rows.add(values);
    } else {
      rows[rowIndex] = values;
    }
    onChanged(table.copyWith(rows: rows));
  }

  void _deleteRow(int index) {
    final rows = [...table.rows]..removeAt(index);
    onChanged(table.copyWith(rows: rows));
  }

  Future<void> _editColumn(BuildContext context, [String? oldName]) async {
    final controller = TextEditingController(text: oldName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: Text(
          context.l10n.text(oldName == null ? 'Add field' : 'Edit field'),
        ),
        icon: Icons.view_column_outlined,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.text('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.l10n.text('Save')),
          ),
        ],
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.text('Field name'),
          ),
          onSubmitted: (_) => Navigator.of(dialogContext).pop(controller.text),
        ),
      ),
    ).whenComplete(controller.dispose);
    if (!context.mounted || value == null) return;
    final name = value.trim();
    if (name.isEmpty || (table.columns.contains(name) && name != oldName)) {
      return;
    }
    if (oldName == null) {
      onChanged(
        table.copyWith(
          columns: [...table.columns, name],
          rows: [
            for (final row in table.rows) {...row, name: ''},
          ],
        ),
      );
    } else if (name != oldName) {
      onChanged(
        table.copyWith(
          columns: [
            for (final column in table.columns)
              column == oldName ? name : column,
          ],
          rows: [
            for (final row in table.rows)
              {
                for (final entry in row.entries)
                  (entry.key == oldName ? name : entry.key): entry.value,
              },
          ],
        ),
      );
    }
  }

  void _deleteColumn(BuildContext context, String column) {
    if (table.columns.length == 1) return;
    onChanged(
      table.copyWith(
        columns: table.columns.where((item) => item != column).toList(),
        rows: [
          for (final row in table.rows)
            {
              for (final entry in row.entries)
                if (entry.key != column) entry.key: entry.value,
            },
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              context.l10n.text('Editable record rows'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < AppBreakpoints.tablet;
              if (compact) {
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: table.rows.take(50).length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _MobileRecordCard(
                    row: table.rows[index],
                    columns: table.columns,
                    rowNumber: index + 1,
                    disabled: disabled,
                    onEdit: () => _editRow(context, index),
                    onDelete: () => _deleteRow(index),
                    onEditColumn: (column) => _editColumn(context, column),
                    onDeleteColumn: (column) => _deleteColumn(context, column),
                  ),
                );
              }
              final tableWidth =
                  constraints.maxWidth > (table.columns.length * 190.0 + 92.0)
                  ? constraints.maxWidth
                  : table.columns.length * 190.0 + 92.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    horizontalMargin: AppSpacing.md,
                    columnSpacing: AppSpacing.md,
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.primaryContainer,
                    ),
                    columns: [
                      for (final column in table.columns)
                        DataColumn(
                          label: _ColumnHeader(
                            column: column,
                            onEdit: disabled
                                ? null
                                : () => _editColumn(context, column),
                            onDelete: disabled
                                ? null
                                : () => _deleteColumn(context, column),
                          ),
                        ),
                      DataColumn(
                        label: Wrap(
                          spacing: AppSpacing.xxs,
                          children: [
                            IconButton(
                              tooltip: context.l10n.text('Add field'),
                              onPressed: disabled
                                  ? null
                                  : () => _editColumn(context),
                              icon: const Icon(Icons.add_box_outlined),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              tooltip: context.l10n.text('Add record row'),
                              onPressed: disabled
                                  ? null
                                  : () => _editRow(context, null),
                              icon: const Icon(Icons.person_add_alt_1),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: [
                      for (
                        var index = 0;
                        index < table.rows.take(50).length;
                        index++
                      )
                        DataRow(
                          cells: [
                            for (final column in table.columns)
                              DataCell(
                                Text(table.rows[index][column] ?? ''),
                                onTap: disabled
                                    ? null
                                    : () => _editRow(context, index),
                              ),
                            DataCell(
                              IconButton(
                                tooltip: context.l10n.text('Delete record row'),
                                onPressed: disabled
                                    ? null
                                    : () => _deleteRow(index),
                                icon: const Icon(Icons.delete_outline),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
