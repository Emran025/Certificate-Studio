part of '../settings_screen.dart';

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialColor,
    required this.title,
    required this.closeLabel,
    required this.applyLabel,
  });

  final Color initialColor;
  final String title;
  final String closeLabel;
  final String applyLabel;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}
