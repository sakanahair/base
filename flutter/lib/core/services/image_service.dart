import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ImageService extends ChangeNotifier {
  static const String _localStoragePrefix = 'sakana_images_';
  final Map<String, List<ServiceImage>> _imageCache = {};
  FirebaseStorage? _storage;
  
  ImageService() {
    // Firebase Storage を初期化（すべてのプラットフォーム）
    try {
      _storage = FirebaseStorage.instance;
    } catch (e) {
      print('Firebase Storage initialization error: $e');
      // Firebase Storageが利用できない場合はLocalStorageのみで動作
    }
  }
  final Uuid _uuid = const Uuid();
  
  // 画像をアップロード（Firebase Storage優先、LocalStorageは軽量化）
  Future<ServiceImage> uploadImage({
    required String serviceId,
    required Uint8List imageData,
    required String fileName,
  }) async {
    try {
      final imageId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();
      
      // 画像をリサイズして軽量化（サムネイル用）
      final thumbnailData = await _createThumbnail(imageData);
      final thumbnailBase64 = thumbnailData != null ? base64Encode(thumbnailData) : '';
      
      // Firebase Storageに先にアップロード
      String firebaseUrl = '';
      if (_storage != null) {
        final url = await _uploadToFirebase(imageId, serviceId, imageData, fileName);
        if (url != null) {
          firebaseUrl = url;
        }
      }
      
      final image = ServiceImage(
        id: imageId,
        serviceId: serviceId,
        localData: thumbnailBase64, // サムネイルのみ保存
        fileName: fileName,
        uploadedAt: timestamp,
        firebaseUrl: firebaseUrl,
        size: imageData.length,
      );
      
      // キャッシュに追加
      if (!_imageCache.containsKey(serviceId)) {
        _imageCache[serviceId] = [];
      }
      _imageCache[serviceId]!.add(image);
      
      // LocalStorageに保存（URLとメタデータのみ）
      await _saveToLocalStorage(serviceId);
      
      notifyListeners();
      return image;
    } catch (e) {
      print('Error uploading image: $e');
      
      // LocalStorage容量エラーの場合はクリア
      if (e.toString().contains('QuotaExceededError')) {
        await _clearOldImages();
        // リトライ
        return uploadImage(
          serviceId: serviceId,
          imageData: imageData,
          fileName: fileName,
        );
      }
      rethrow;
    }
  }
  
  // サムネイル作成（実装は簡略化）
  Future<Uint8List?> _createThumbnail(Uint8List imageData) async {
    // 画像サイズが100KB以下ならそのまま返す
    if (imageData.length <= 100 * 1024) {
      return imageData;
    }
    // それ以上なら null を返してLocalStorageには保存しない
    return null;
  }
  
  // 古い画像データをクリア
  Future<void> _clearOldImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_localStoragePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      _imageCache.clear();
      print('Cleared old image data from LocalStorage');
    } catch (e) {
      print('Error clearing old images: $e');
    }
  }
  
  // パブリックメソッド: キャッシュをクリア
  Future<void> clearCache() async {
    await _clearOldImages();
    notifyListeners();
  }
  
  // Firebase Storageにアップロード
  Future<String?> _uploadToFirebase(
    String imageId,
    String serviceId,
    Uint8List imageData,
    String fileName,
  ) async {
    if (_storage == null) return null;
    
    try {
      final tenantId = await _getTenantId();
      final path = 'tenants/$tenantId/services/$serviceId/$imageId';
      final ref = _storage!.ref(path);
      
      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'serviceId': serviceId,
          'fileName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // アップロード
      final uploadTask = await ref.putData(imageData, metadata);
      final url = await uploadTask.ref.getDownloadURL();
      
      print('Image uploaded to Firebase: $url');
      return url;
    } catch (e) {
      print('Error uploading to Firebase Storage: $e');
      return null;
    }
  }
  
  // サービスの画像を取得
  Future<List<ServiceImage>> getServiceImages(String serviceId) async {
    // キャッシュから取得
    if (_imageCache.containsKey(serviceId)) {
      return _imageCache[serviceId]!;
    }
    
    // LocalStorageから読み込み
    final prefs = await SharedPreferences.getInstance();
    final key = '$_localStoragePrefix$serviceId';
    final jsonString = prefs.getString(key);
    
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List;
      final images = jsonList.map((json) => ServiceImage.fromJson(json)).toList();
      _imageCache[serviceId] = images;
      return images;
    }
    
    return [];
  }
  
  // 画像を削除
  Future<void> deleteImage(String serviceId, String imageId) async {
    if (!_imageCache.containsKey(serviceId)) {
      await getServiceImages(serviceId);
    }
    
    final images = _imageCache[serviceId] ?? [];
    final image = images.firstWhere((img) => img.id == imageId);
    
    // LocalStorageから削除
    images.removeWhere((img) => img.id == imageId);
    _imageCache[serviceId] = images;
    await _saveToLocalStorage(serviceId);
    
    // Firebase Storageから削除（バックグラウンド）
    if (image.firebaseUrl.isNotEmpty) {
      _deleteFromFirebase(image.firebaseUrl);
    }
    
    notifyListeners();
  }
  
  // Firebase Storageから削除
  Future<void> _deleteFromFirebase(String url) async {
    if (_storage == null) return;
    
    try {
      final ref = _storage!.refFromURL(url);
      await ref.delete();
      print('Image deleted from Firebase Storage');
    } catch (e) {
      print('Error deleting from Firebase Storage: $e');
    }
  }
  
  // 画像の並び順を変更
  Future<void> reorderImages(String serviceId, int oldIndex, int newIndex) async {
    if (!_imageCache.containsKey(serviceId)) {
      await getServiceImages(serviceId);
    }
    
    final images = _imageCache[serviceId]!;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);
    
    await _saveToLocalStorage(serviceId);
    notifyListeners();
  }
  
  // LocalStorageに保存
  Future<void> _saveToLocalStorage(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_localStoragePrefix$serviceId';
    final images = _imageCache[serviceId] ?? [];
    final jsonList = images.map((img) => img.toJson()).toList();
    await prefs.setString(key, json.encode(jsonList));
  }
  
  // テナントIDを取得
  Future<String> _getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tenantId') ?? 'default';
  }
  
  // ファイル名からコンテンツタイプを判定
  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
  
  // サービスのすべての画像を削除
  Future<void> deleteAllServiceImages(String serviceId) async {
    final images = await getServiceImages(serviceId);
    
    // LocalStorageから削除
    _imageCache.remove(serviceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_localStoragePrefix$serviceId');
    
    // Firebase Storageから削除（バックグラウンド）
    for (final image in images) {
      if (image.firebaseUrl.isNotEmpty) {
        _deleteFromFirebase(image.firebaseUrl);
      }
    }
    
    notifyListeners();
  }
}

// 画像モデル
class ServiceImage {
  final String id;
  final String serviceId;
  final String localData; // Base64エンコードされた画像データ
  String firebaseUrl;
  final String fileName;
  final String uploadedAt;
  final int size;
  
  ServiceImage({
    required this.id,
    required this.serviceId,
    required this.localData,
    required this.firebaseUrl,
    required this.fileName,
    required this.uploadedAt,
    required this.size,
  });
  
  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      id: json['id'],
      serviceId: json['serviceId'],
      localData: json['localData'] ?? '',
      firebaseUrl: json['firebaseUrl'] ?? '',
      fileName: json['fileName'],
      uploadedAt: json['uploadedAt'],
      size: json['size'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'localData': localData,
      'firebaseUrl': firebaseUrl,
      'fileName': fileName,
      'uploadedAt': uploadedAt,
      'size': size,
    };
  }
  
  // Base64データをUint8Listに変換
  Uint8List get imageBytes => base64Decode(localData);
  
  // ファイルサイズを人間が読みやすい形式で取得
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}