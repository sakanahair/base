import 'dart:typed_data';
import 'dart:async';

class ImageCompressorWeb {
  /// スタブ実装（Web以外のプラットフォーム用）
  static Future<Uint8List> compressImage({
    required Uint8List imageData,
    required String fileName,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
    int targetSizeBytes = 2 * 1024 * 1024,
  }) async {
    // Web以外のプラットフォームでは元の画像をそのまま返す
    return imageData;
  }
}