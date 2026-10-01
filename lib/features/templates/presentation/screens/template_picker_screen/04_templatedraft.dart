part of '../template_picker_screen.dart';

class _TemplateDraft {
  const _TemplateDraft({
    required this.name,
    required this.path,
    required this.width,
    required this.height,
    required this.dpi,
    required this.format,
  });
  final String name;
  final String path;
  final int width;
  final int height;
  final double dpi;
  final String format;
}
