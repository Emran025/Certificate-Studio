import 'package:image/image.dart' as image;

String templatePixelHexColor(
  image.Image decodedImage,
  double normalizedX,
  double normalizedY,
) {
  final x = (normalizedX.clamp(0.0, 1.0) * (decodedImage.width - 1)).round();
  final y = (normalizedY.clamp(0.0, 1.0) * (decodedImage.height - 1)).round();
  final pixel = decodedImage.getPixel(x, y);
  final channels = [pixel.r, pixel.g, pixel.b];
  return '#${channels.map((channel) => channel.toInt().toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
}
