import 'dart:io';
import 'dart:typed_data';

// シンプルなアイコン生成スクリプト
void main() async {
  print('Generating missing icons...');
  
  // 必要なアイコンサイズ
  final sizes = [16, 32, 48, 64, 72, 96, 120, 128, 144, 152, 180, 192, 256, 384, 512];
  
  // iconsディレクトリを作成
  await Directory('icons').create(recursive: true);
  
  for (final size in sizes) {
    await generateSimpleIcon(size);
    print('Generated Icon-$size.png');
  }
  
  // favicon.icoを生成（16x16のPNG）
  await generateSimpleFavicon();
  print('Generated favicon.ico');
  
  print('All icons generated successfully!');
  print('Now copy these files to /Users/apple/DEV/SAKANA_AI/next/public/admin/');
}

// シンプルなPNGアイコンを生成（単色背景にテキスト）
Future<void> generateSimpleIcon(int size) async {
  // PNGヘッダーとシンプルな単色画像データを作成
  final bytes = createSimplePng(size, size, 93, 155, 155); // SAKANA teal color
  
  final file = File('icons/Icon-$size.png');
  await file.writeAsBytes(bytes);
}

// favicon.icoを生成
Future<void> generateSimpleFavicon() async {
  // 16x16のシンプルなPNGを作成
  final bytes = createSimplePng(16, 16, 93, 155, 155);
  
  final file = File('favicon.ico');
  await file.writeAsBytes(bytes);
}

// シンプルな単色PNGを生成
Uint8List createSimplePng(int width, int height, int r, int g, int b) {
  // PNG署名
  final signature = [137, 80, 78, 71, 13, 10, 26, 10];
  
  // IHDRチャンク
  final ihdr = [
    ...intToBytes(13, 4), // チャンクサイズ
    ...stringToBytes('IHDR'),
    ...intToBytes(width, 4),
    ...intToBytes(height, 4),
    8, // ビット深度
    2, // カラータイプ (RGB)
    0, // 圧縮方法
    0, // フィルター方法
    0, // インターレース方法
  ];
  final ihdrCrc = crc32(ihdr.sublist(4));
  ihdr.addAll(intToBytes(ihdrCrc, 4));
  
  // IDATチャンク（圧縮なしの生データ）
  final imageData = <int>[];
  for (int y = 0; y < height; y++) {
    imageData.add(0); // フィルタータイプ
    for (int x = 0; x < width; x++) {
      imageData.addAll([r, g, b]); // RGB値
    }
  }
  
  // zlib圧縮（簡易版）
  final compressed = simpleDeflate(imageData);
  
  final idat = [
    ...intToBytes(compressed.length, 4),
    ...stringToBytes('IDAT'),
    ...compressed,
  ];
  final idatCrc = crc32(idat.sublist(4, idat.length));
  idat.addAll(intToBytes(idatCrc, 4));
  
  // IENDチャンク
  final iend = [
    ...intToBytes(0, 4),
    ...stringToBytes('IEND'),
    ...intToBytes(0xAE426082, 4), // 固定CRC
  ];
  
  // 全体を結合
  return Uint8List.fromList([
    ...signature,
    ...ihdr,
    ...idat,
    ...iend,
  ]);
}

// 簡易deflate圧縮
List<int> simpleDeflate(List<int> data) {
  // zlib header
  final result = [0x78, 0x9C];
  
  // 圧縮なしブロック
  final blockSize = 65535;
  for (int i = 0; i < data.length; i += blockSize) {
    final remaining = data.length - i;
    final currentBlockSize = remaining > blockSize ? blockSize : remaining;
    final isLast = i + currentBlockSize >= data.length;
    
    result.add(isLast ? 1 : 0); // BFINAL & BTYPE
    result.addAll(intToBytes(currentBlockSize, 2)); // LEN
    result.addAll(intToBytes(~currentBlockSize & 0xFFFF, 2)); // NLEN
    result.addAll(data.sublist(i, i + currentBlockSize)); // DATA
  }
  
  // Adler-32チェックサム
  final adler = adler32(data);
  result.addAll(intToBytes(adler, 4));
  
  return result;
}

// Adler-32チェックサム
int adler32(List<int> data) {
  int a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

// CRC-32計算
int crc32(List<int> data) {
  const table = [
    0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA,
    0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
    0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
    0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
  ];
  
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc = table[(crc ^ byte) & 0x0F] ^ (crc >> 4);
    crc = table[(crc ^ (byte >> 4)) & 0x0F] ^ (crc >> 4);
  }
  return crc ^ 0xFFFFFFFF;
}

// 整数をバイト列に変換
List<int> intToBytes(int value, int length) {
  final bytes = <int>[];
  for (int i = length - 1; i >= 0; i--) {
    bytes.add((value >> (i * 8)) & 0xFF);
  }
  return bytes;
}

// 文字列をバイト列に変換
List<int> stringToBytes(String str) {
  return str.codeUnits;
}