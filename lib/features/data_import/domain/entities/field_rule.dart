enum FieldRuleKind { text, number, choice }

class FieldRule {
  const FieldRule({
    required this.kind,
    this.min,
    this.max,
    this.choices = const [],
  });

  final FieldRuleKind kind;
  final double? min;
  final double? max;
  final List<String> choices;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'min': min,
    'max': max,
    'choices': choices,
  };

  factory FieldRule.fromJson(Map<String, Object?> json) {
    final rawKind = json['kind'];
    final kind = FieldRuleKind.values.firstWhere(
      (candidate) => candidate.name == rawKind,
      orElse: () => FieldRuleKind.text,
    );
    final rawChoices = json['choices'];
    return FieldRule(
      kind: kind,
      min: _parseDouble(json['min']),
      max: _parseDouble(json['max']),
      choices: rawChoices is List
          ? [for (final choice in rawChoices) choice.toString()]
          : const [],
    );
  }
}

double? _parseDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
