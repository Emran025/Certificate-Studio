part of '../certificate_designer_screen.dart';

class _DesignerField {
  const _DesignerField({
    required this.id,
    required this.className,
    required this.source,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.color,
    this.text = '',
    this.alignment = 'left',
    this.direction = 'ltr',
    this.fontFamily = 'Cairo',
    this.bold = false,
    this.italic = false,
    this.qr = false,
  });
  final String id;
  final String className;
  final String source;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final String color;
  final String text;
  final String alignment;
  final String direction;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final bool qr;
  Alignment get textAlignment => switch (alignment) {
    'center' => Alignment.center,
    'right' => Alignment.centerRight,
    _ => Alignment.centerLeft,
  };
  TextDirection get textDirection =>
      direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

  factory _DesignerField.fromRow(Map<String, Object?> row) {
    final position = _decode(row['position_json']);
    final style = _decode(row['style_json']);
    return _DesignerField(
      id: row['id']! as String,
      className: canonicalFieldClassId(row['class_name']! as String),
      source: (row['source'] as String?) ?? '',
      text: (style['text'] as String?) ?? '',
      x: _number(position['x'], 100),
      y: _number(position['y'], 100),
      width: _number(position['width'], 420),
      height: _number(position['height'], 64),
      fontSize: _number(style['font_size'], 28),
      color: (style['color'] as String?) ?? '#20332B',
      alignment: (style['alignment'] as String?) ?? 'left',
      direction: (style['direction'] as String?) ?? 'ltr',
      fontFamily: (style['font_family'] as String?) ?? 'Cairo',
      bold: style['bold'] == true || style['font_weight'] == 'bold',
      italic: style['italic'] == true,
      qr: style['kind'] == 'qr',
    );
  }
  Map<String, Object?> toRow(String projectId, String now) => {
    'id': id,
    'project_id': projectId,
    'class_name': canonicalFieldClassId(className),
    'source': source,
    'position_json': jsonEncode({
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    }),
    'style_json': jsonEncode({
      'kind': qr ? 'qr' : (text.isNotEmpty ? 'static' : 'text'),
      'text': text,
      'font_size': fontSize,
      'color': color,
      'alignment': alignment,
      'direction': direction,
      'font_family': fontFamily,
      'font_weight': bold ? 'bold' : 'normal',
      'bold': bold,
      'italic': italic,
    }),
    'created_at': now,
    'updated_at': now,
  };
  _DesignerField copyWith({
    String? className,
    String? source,
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    double? fontSize,
    String? color,
    String? alignment,
    String? direction,
    String? fontFamily,
    bool? bold,
    bool? italic,
    bool? qr,
  }) => _DesignerField(
    id: id,
    className: className ?? this.className,
    source: source ?? this.source,
    text: text ?? this.text,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    alignment: alignment ?? this.alignment,
    direction: direction ?? this.direction,
    fontFamily: fontFamily ?? this.fontFamily,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    qr: qr ?? this.qr,
  );
  static Map<String, Object?> _decode(Object? raw) {
    if (raw is! String) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, Object?>.from(value) : {};
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
