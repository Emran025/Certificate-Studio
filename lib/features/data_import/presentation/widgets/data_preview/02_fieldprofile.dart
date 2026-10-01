part of '../data_preview.dart';

class _FieldProfile {
  const _FieldProfile({
    required this.kind,
    this.choices = const [],
    this.min,
    this.max,
  });

  final _FieldKind kind;
  final List<String> choices;
  final double? min;
  final double? max;
}
