import 'dart:io';

import 'package:image/image.dart' as img;

const int size = 1024;
final img.Color white = img.ColorRgba8(255, 255, 255, 255);
final img.Color capShadow = img.ColorRgba8(15, 23, 42, 40);

img.Image fillGradient(int fromRgb, int toRgb) {
  final top = (fromRgb >> 16) & 0xff, tg = (fromRgb >> 8) & 0xff, tb = fromRgb & 0xff;
  final bot = (toRgb >> 16) & 0xff, bg = (toRgb >> 8) & 0xff, bb = toRgb & 0xff;
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (top + (bot - top) * t).round();
    final g = (tg + (bg - tg) * t).round();
    final b = (tb + (bb - tb) * t).round();
    for (var x = 0; x < size; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return image;
}

void drawCap(img.Image image) {
  // Mortarboard (diamond seen at an angle).
  img.fillPolygon(image,
      vertices: [
        img.Point(512, 320),
        img.Point(724, 420),
        img.Point(512, 520),
        img.Point(300, 420),
      ],
      color: white);
  // Soft shadow under the mortarboard.
  img.fillPolygon(image,
      vertices: [
        img.Point(492, 512),
        img.Point(704, 424),
        img.Point(716, 430),
        img.Point(504, 522),
      ],
      color: capShadow);
  // Skullcap base.
  img.fillPolygon(image,
      vertices: [
        img.Point(448, 510),
        img.Point(576, 510),
        img.Point(596, 596),
        img.Point(428, 596),
      ],
      color: white);
  // Tassel cord.
  img.drawLine(image,
      x1: 690, y1: 416, x2: 762, y2: 468,
      color: white, thickness: 12, antialias: true);
  // Tassel button.
  img.fillCircle(image, x: 768, y: 484, radius: 22, color: white, antialias: true);
  // Tassel fringe.
  img.fillPolygon(image,
      vertices: [
        img.Point(740, 500),
        img.Point(796, 500),
        img.Point(768, 566),
      ],
      color: white);
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  final icon = fillGradient(0x2563EB, 0x1E3A8A);
  drawCap(icon);
  File('assets/icon/icon.png')
      .writeAsBytesSync(img.encodePng(icon));

  // Adaptive foreground: transparent background, glyph kept in the central
  // safe zone (approx. 66% circle centered on the image).
  final foreground = img.Image(width: size, height: size);
  drawCap(foreground);
  File('assets/icon/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  stdout.writeln('Generated assets/icon/icon.png and icon_foreground.png');
}