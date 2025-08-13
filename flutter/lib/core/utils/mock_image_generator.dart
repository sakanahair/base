import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MockImageGenerator {
  // モック画像を生成（色と番号付き）
  static Future<Uint8List> generateMockImage({
    required int index,
    required Color color,
    required String text,
    int width = 800,
    int height = 600,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    
    // 背景を描画
    final bgPaint = Paint()..color = color.withOpacity(0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );
    
    // グリッドパターンを描画
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), height.toDouble()),
        gridPaint,
      );
    }
    
    for (int i = 0; i <= height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(width.toDouble(), i.toDouble()),
        gridPaint,
      );
    }
    
    // 中央に円を描画
    final circlePaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      100,
      circlePaint,
    );
    
    // テキストを描画
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );
    
    // インデックス番号を描画
    final indexPainter = TextPainter(
      text: TextSpan(
        text: '#${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    indexPainter.layout();
    indexPainter.paint(
      canvas,
      const Offset(20, 20),
    );
    
    // 画像に変換
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  // 商品カテゴリごとのモック画像を生成
  static Future<List<Uint8List>> generateProductImages(String category, int count) async {
    final List<Uint8List> images = [];
    
    final categoryColors = {
      'カット': Colors.blue,
      'カラー': Colors.purple,
      'パーマ': Colors.orange,
      'トリートメント': Colors.green,
      'ランチ': Colors.amber,
      'ディナー': Colors.indigo,
      '商品': Colors.teal,
      '配送': Colors.brown,
      '診察': Colors.cyan,
      '検査': Colors.pink,
      'パーソナル': Colors.deepOrange,
      'ヨガ': Colors.lightGreen,
    };
    
    final color = categoryColors[category] ?? Colors.grey;
    
    for (int i = 0; i < count; i++) {
      final image = await generateMockImage(
        index: i,
        color: color,
        text: category,
      );
      images.add(image);
    }
    
    return images;
  }
  
  // サービス業種に応じたモック画像セットを生成
  static Future<Map<String, List<Uint8List>>> generateIndustryImages(String industry) async {
    final Map<String, List<Uint8List>> imageMap = {};
    
    switch (industry) {
      case 'beauty':
        imageMap['style1'] = await generateProductImages('カット', 3);
        imageMap['style2'] = await generateProductImages('カラー', 2);
        imageMap['style3'] = await generateProductImages('パーマ', 2);
        break;
      
      case 'restaurant':
        imageMap['menu1'] = await generateProductImages('ランチ', 4);
        imageMap['menu2'] = await generateProductImages('ディナー', 3);
        break;
      
      case 'retail':
        imageMap['product1'] = await generateProductImages('商品', 5);
        imageMap['product2'] = await generateProductImages('商品', 3);
        break;
      
      default:
        imageMap['default'] = await generateProductImages('サービス', 2);
    }
    
    return imageMap;
  }
}