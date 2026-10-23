import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

Map<String, dynamic>? decodeQrRecord(List<int> bytes) {
  try {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;

    final reader = QRCodeReader();
    final hints = DecodeHints()
      ..put(DecodeHintType.tryHarder)
      ..put(DecodeHintType.possibleFormats, [BarcodeFormat.qrCode]);
    final grayscale = img.grayscale(decoded.clone());
    final variants = <img.Image>[
      decoded,
      grayscale,
      img.adjustColor(grayscale.clone(), contrast: 1.35),
      img.invert(grayscale.clone()),
      img.copyRotate(grayscale.clone(), angle: 90),
      img.copyRotate(grayscale.clone(), angle: 180),
      img.copyRotate(grayscale.clone(), angle: 270),
    ];
    // Upscale only smaller source images, using nearest-neighbor sampling so
    // QR module edges stay crisp rather than being blurred by interpolation.
    if (_maxDimension(grayscale) <= 2000) {
      variants.add(
        img.copyResize(
          grayscale,
          width: grayscale.width * 2,
          height: grayscale.height * 2,
          interpolation: img.Interpolation.nearest,
        ),
      );
    }
    if (_maxDimension(grayscale) <= 1000) {
      variants.add(
        img.copyResize(
          grayscale,
          width: grayscale.width * 3,
          height: grayscale.height * 3,
          interpolation: img.Interpolation.nearest,
        ),
      );
    }

    // A QR can occupy only a small part of a certificate. Search overlapping
    // crops at several sizes so nearby text and template artwork are less
    // likely to hide its finder patterns from the detector.
    final crops = <img.Image>[];
    for (final fraction in [0.75, 0.5, 0.33]) {
      final cropWidth = (grayscale.width * fraction)
          .round()
          .clamp(1, grayscale.width)
          .toInt();
      final cropHeight = (grayscale.height * fraction)
          .round()
          .clamp(1, grayscale.height)
          .toInt();
      final maxX = grayscale.width - cropWidth;
      final maxY = grayscale.height - cropHeight;
      final xStep = (cropWidth ~/ 2).clamp(1, grayscale.width).toInt();
      final yStep = (cropHeight ~/ 2).clamp(1, grayscale.height).toInt();
      final xPositions = _overlappingStarts(maxX, xStep);
      final yPositions = _overlappingStarts(maxY, yStep);
      for (final top in yPositions) {
        for (final left in xPositions) {
          crops.add(
            img.copyCrop(
              grayscale,
              x: left,
              y: top,
              width: cropWidth,
              height: cropHeight,
            ),
          );
          if (crops.length >= 20) break;
        }
        if (crops.length >= 20) break;
      }
      if (crops.length >= 20) break;
    }
    variants.addAll(crops);

    // Losslessly enlarge smaller crops as well. Cropping before enlargement
    // keeps this bounded for high-resolution scans and photos.
    for (final crop in crops) {
      if (_maxDimension(crop) <= 900) {
        variants.add(
          img.copyResize(
            crop,
            width: crop.width * 2,
            height: crop.height * 2,
            interpolation: img.Interpolation.nearest,
          ),
        );
      }
    }

    for (final variant in variants) {
      // QR modules are achromatic; grayscale input keeps channel order from
      // affecting luminance when passed to zxing2.
      final rgba = variant
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.rgba);
      final source = RGBLuminanceSource(
        variant.width,
        variant.height,
        rgba.buffer.asInt32List(),
      );
      for (final binarizer in [
        GlobalHistogramBinarizer(source),
        HybridBinarizer(source),
      ]) {
        try {
          final result = reader.decode(BinaryBitmap(binarizer), hints: hints);
          return decodeVerificationQrPayload(result.text);
        } catch (_) {
          // Continue through the remaining preprocessing and crop variants.
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

int _maxDimension(img.Image image) =>
    image.width > image.height ? image.width : image.height;

List<int> _overlappingStarts(int maxStart, int step) {
  if (maxStart <= 0) return [0];
  final starts = <int>[];
  for (var value = 0; value < maxStart; value += step) {
    starts.add(value);
  }
  if (starts.last != maxStart) starts.add(maxStart);
  return starts;
}
