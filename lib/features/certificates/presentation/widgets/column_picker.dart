part of '../screens/certificate_designer_screen.dart';

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({required this.columns});
  final List<String> columns;
  @override
  Widget build(BuildContext context) => AppDialog(
    title: Text(context.l10n.text('Add data field')),
    icon: Icons.view_column_outlined,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.text('Cancel')),
      ),
    ],
    child: SizedBox(
      width: 360,
      child: columns.isEmpty
          ? const Text(
              'Import recipient data first so fields can be mapped to columns.',
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final column in columns)
                  ListTile(
                    leading: const Icon(Icons.view_column_outlined),
                    title: Text(column),
                    onTap: () => Navigator.pop(context, column),
                  ),
              ],
            ),
    ),
  );
}
