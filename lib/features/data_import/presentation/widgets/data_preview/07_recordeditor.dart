part of '../data_preview.dart';

class _RecordEditor extends StatefulWidget {
  const _RecordEditor({
    required this.columns,
    required this.profiles,
    required this.initialValues,
  });

  final List<String> columns;
  final Map<String, _FieldProfile> profiles;
  final Map<String, String> initialValues;

  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}
