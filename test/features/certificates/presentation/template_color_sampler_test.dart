import 'package:certificate_studio/features/certificates/presentation/utils/template_color_sampler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('samples the requested image pixel as an opaque hex color', () {
    final decoded = image.Image(width: 2, height: 2);
    decoded.setPixelRgb(0, 0, 12, 34, 56);
    decoded.setPixelRgb(1, 1, 200, 150, 100);

    expect(templatePixelHexColor(decoded, 0, 0), '#0C2238');
    expect(templatePixelHexColor(decoded, 1, 1), '#C89664');
    expect(templatePixelHexColor(decoded, 5, 2), '#C89664');
  });
}
