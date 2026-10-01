part of '../settings_screen.dart';

class _HueSelectionPainter extends CustomPainter {
  const _HueSelectionPainter({required this.x});

  final double x;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(x - 2, 0, 4, size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 3, -1, 6, size.height + 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_HueSelectionPainter oldDelegate) => oldDelegate.x != x;
}
