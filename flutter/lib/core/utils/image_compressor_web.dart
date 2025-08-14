import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;

class ImageCompressorWeb {
  /// Web環境で画像を圧縮
  static Future<Uint8List> compressImage({
    required Uint8List imageData,
    required String fileName,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
    int targetSizeBytes = 2 * 1024 * 1024, // 2MB
  }) async {
    try {
      developer.log(
        'Starting web compression - Original size: ${(imageData.length / 1024 / 1024).toStringAsFixed(2)}MB',
        name: 'ImageCompressorWeb',
      );

      // Blobを作成
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // 画像要素を作成して読み込み
      final img = html.ImageElement(src: url);
      
      // タイムアウト付きで画像読み込みを待つ
      try {
        await img.onLoad.first.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Image loading timeout');
          },
        );
      } catch (e) {
        html.Url.revokeObjectUrl(url);
        developer.log('Failed to load image: $e', name: 'ImageCompressorWeb', error: e);
        throw Exception('画像の読み込みに失敗しました');
      }
      
      // 元の画像サイズを取得
      final originalWidth = img.naturalWidth ?? img.width ?? 1920;
      final originalHeight = img.naturalHeight ?? img.height ?? 1920;
      
      developer.log(
        'Original dimensions: ${originalWidth}x${originalHeight}',
        name: 'ImageCompressorWeb',
      );
      
      // リサイズ後のサイズを計算（アグレッシブにリサイズ）
      double scale = 1.0;
      
      // ファイルサイズに応じてより積極的にリサイズ
      if (imageData.length > 5 * 1024 * 1024) { // 5MB以上
        maxWidth = 1280;
        maxHeight = 1280;
      } else if (imageData.length > 3 * 1024 * 1024) { // 3MB以上
        maxWidth = 1600;
        maxHeight = 1600;
      }
      
      if (originalWidth > maxWidth || originalHeight > maxHeight) {
        final scaleWidth = maxWidth / originalWidth;
        final scaleHeight = maxHeight / originalHeight;
        scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;
      }
      
      final newWidth = (originalWidth * scale).round();
      final newHeight = (originalHeight * scale).round();
      
      developer.log(
        'Resizing to: ${newWidth}x${newHeight} (scale: ${scale.toStringAsFixed(2)})',
        name: 'ImageCompressorWeb',
      );
      
      // Canvas要素を作成
      final canvas = html.CanvasElement(width: newWidth, height: newHeight);
      final ctx = canvas.context2D;
      
      // 画像を描画
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);
      
      // 品質を調整しながら圧縮
      Uint8List? compressedData;
      
      // ファイルサイズに応じて初期品質を調整
      int currentQuality;
      if (imageData.length > 5 * 1024 * 1024) { // 5MB以上
        currentQuality = 60; // 低品質から開始
      } else if (imageData.length > 3 * 1024 * 1024) { // 3MB以上
        currentQuality = 70;
      } else {
        currentQuality = quality;
      }
      
      // 常にJPEGで圧縮（PNGは圧縮率が悪い）
      String outputFormat = 'image/jpeg';
      
      while (currentQuality > 5) {
        // toDataURLで圧縮（品質指定）
        final dataUrl = canvas.toDataUrl(outputFormat, currentQuality / 100);
        
        // データURLからバイナリに変換
        final base64Data = dataUrl.split(',')[1];
        compressedData = base64Decode(base64Data);
        
        developer.log(
          'Compressed with quality $currentQuality: ${(compressedData.length / 1024 / 1024).toStringAsFixed(2)}MB',
          name: 'ImageCompressorWeb',
        );
        
        // 目標サイズ以下になったら終了
        if (compressedData.length <= targetSizeBytes) {
          break;
        }
        
        // 品質を下げて再試行（より積極的に）
        if (compressedData.length > targetSizeBytes * 2) {
          currentQuality -= 20; // 大幅に超えている場合は大きく下げる
        } else {
          currentQuality -= 10;
        }
      }
      
      // URLをクリーンアップ
      html.Url.revokeObjectUrl(url);
      
      if (compressedData == null || compressedData.isEmpty) {
        developer.log('Compression failed, returning original', name: 'ImageCompressorWeb');
        return imageData;
      }
      
      final compressionRatio = ((1 - compressedData.length / imageData.length) * 100);
      developer.log(
        'Compression complete - Final size: ${(compressedData.length / 1024 / 1024).toStringAsFixed(2)}MB (${compressionRatio.toStringAsFixed(1)}% reduction)',
        name: 'ImageCompressorWeb',
      );
      
      return compressedData;
      
    } catch (e, stackTrace) {
      developer.log(
        'Compression error: $e',
        name: 'ImageCompressorWeb',
        error: e,
        stackTrace: stackTrace,
      );
      // エラーが発生した場合は元の画像を返す
      return imageData;
    }
  }
}