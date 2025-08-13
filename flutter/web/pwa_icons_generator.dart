import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// PWA用アイコンジェネレーター
// 実行: dart pwa_icons_generator.dart

void main() async {
  print('Generating PWA icons...');
  
  final sizes = [16, 32, 48, 72, 96, 120, 128, 144, 180, 192, 256, 384, 512];
  
  for (final size in sizes) {
    await generateIcon(size);
    print('Generated Icon-$size.png');
  }
  
  // Maskable icons
  await generateMaskableIcon(192);
  await generateMaskableIcon(512);
  print('Generated maskable icons');
  
  print('All icons generated successfully!');
}

Future<void> generateIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  
  // Background gradient
  final gradient = ui.Gradient.linear(
    Offset(0, 0),
    Offset(size.toDouble(), size.toDouble()),
    [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ],
  );
  
  final bgPaint = Paint()
    ..shader = gradient
    ..style = PaintingStyle.fill;
  
  // Rounded rectangle background
  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Radius.circular(size * 0.2),
  );
  canvas.drawRRect(rrect, bgPaint);
  
  // Draw "S" letter
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'S',
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  // Save to file
  final file = File('icons/Icon-$size.png');
  await file.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
}

Future<void> generateMaskableIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  
  // White background for maskable
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = Colors.white,
  );
  
  // Safe area circle (80% of size)
  final safeSize = size * 0.8;
  final offset = (size - safeSize) / 2;
  
  // Gradient circle
  final gradient = ui.Gradient.radial(
    Offset(size / 2, size / 2),
    safeSize / 2,
    [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ],
  );
  
  final paint = Paint()
    ..shader = gradient
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    safeSize / 2,
    paint,
  );
  
  // Draw "S" letter
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'S',
      style: TextStyle(
        color: Colors.white,
        fontSize: safeSize * 0.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  // Save to file
  final file = File('icons/Icon-maskable-$size.png');
  await file.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
}