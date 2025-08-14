import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'simplified_auth_service.dart';

// Web環境用の画像圧縮をインポート
import '../utils/image_compressor_stub.dart'
  if (dart.library.html) '../utils/image_compressor_web.dart';

class ImageService extends ChangeNotifier {
  static const String _localStoragePrefix = 'sakana_images_';
  final Map<String, List<ServiceImage>> _imageCache = {};
  FirebaseStorage? _storage;
  final SimplifiedAuthService _authService = SimplifiedAuthService();
  
  ImageService() {
    // Firebase Storage を初期化（すべてのプラットフォーム）
    try {
      _storage = FirebaseStorage.instance;
      developer.log('ImageService initialized with Firebase Storage: ${_storage != null}', name: 'ImageService');
    } catch (e) {
      developer.log('Firebase Storage initialization error: $e', name: 'ImageService', error: e);
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
    developer.log('uploadImage called - serviceId: $serviceId, fileName: $fileName, size: ${imageData.length} bytes (${(imageData.length / 1024 / 1024).toStringAsFixed(2)} MB)', name: 'ImageService');
    
    // temp_IDや空IDへのアップロードを拒否
    if (serviceId.isEmpty || serviceId.startsWith('temp_')) {
      developer.log('WARNING: Rejecting upload for invalid serviceId: $serviceId', name: 'ImageService');
      throw Exception('正式なサービスIDが必要です。サービスを保存後に画像を追加してください。');
    }
    
    try {
      // 画像を圧縮
      Uint8List compressedData;
      try {
        compressedData = await _compressImage(imageData, fileName);
        developer.log('Image compressed: ${imageData.length} → ${compressedData.length} bytes', name: 'ImageService');
      } catch (compressError) {
        developer.log('Compression error: $compressError', name: 'ImageService', error: compressError);
        throw Exception('画像の圧縮に失敗しました: $compressError');
      }
      
      final imageId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();
      
      // Firebase Storageに先にアップロード
      String firebaseUrl = '';
      if (_storage != null) {
        developer.log('Attempting Firebase upload...', name: 'ImageService');
        final url = await _uploadToFirebase(imageId, serviceId, compressedData, fileName);
        if (url != null) {
          firebaseUrl = url;
          developer.log('Firebase upload successful: $url', name: 'ImageService');
          developer.log('Firebase URL will be used for service: $serviceId', name: 'ImageService');
        } else {
          developer.log('Firebase upload returned null', name: 'ImageService');
        }
      } else {
        developer.log('Firebase Storage is not initialized', name: 'ImageService');
      }
      
      // Firebase URLがある場合はBase64データを保存しない（容量節約）
      String localDataBase64 = '';
      if (firebaseUrl.isEmpty) {
        // Firebase URLがない場合のみBase64データを保存
        localDataBase64 = base64Encode(compressedData);
        developer.log('Base64 encoded: ${localDataBase64.length} chars', name: 'ImageService');
      } else {
        developer.log('Using Firebase URL, skipping Base64 encoding to save space', name: 'ImageService');
      }
      
      final image = ServiceImage(
        id: imageId,
        serviceId: serviceId,
        localData: localDataBase64,
        fileName: fileName,
        uploadedAt: timestamp,
        firebaseUrl: firebaseUrl,
        size: compressedData.length,
      );
      
      // キャッシュに追加
      if (!_imageCache.containsKey(serviceId)) {
        _imageCache[serviceId] = [];
      }
      _imageCache[serviceId]!.add(image);
      
      // LocalStorageに保存（URLとメタデータのみ）
      await _saveToLocalStorage(serviceId);
      
      notifyListeners();
      developer.log('Image uploaded successfully - id: ${image.id}', name: 'ImageService');
      return image;
    } catch (e, stackTrace) {
      developer.log('Error uploading image: $e', name: 'ImageService', error: e, stackTrace: stackTrace);
      
      // LocalStorage容量エラーの場合はクリア
      if (e.toString().contains('QuotaExceededError')) {
        developer.log('QuotaExceededError detected, clearing old images...', name: 'ImageService');
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
  
  
  // 画像データを圧縮（アップロード前の処理）
  Future<Uint8List> _compressImage(Uint8List imageData, String fileName) async {
    // 目標サイズを2MBに設定
    const targetSize = 2 * 1024 * 1024; // 2MB
    const maxSize = 10 * 1024 * 1024; // 10MB（絶対的な上限）
    const bool skipCompression = true; // デバッグ用：trueにすると圧縮をスキップ
    
    developer.log(
      'Processing image: ${fileName}, original size: ${imageData.length} bytes (${(imageData.length / 1024 / 1024).toStringAsFixed(2)} MB)',
      name: 'ImageService',
    );
    
    // デバッグ：圧縮をスキップ
    if (skipCompression) {
      developer.log('Skipping compression (debug mode)', name: 'ImageService');
      if (imageData.length > maxSize) {
        throw Exception('画像が大きすぎます（${(imageData.length / 1024 / 1024).toStringAsFixed(1)}MB）。10MB以下の画像を選択してください。');
      }
      return imageData;
    }
    
    // 2MB以下の場合はそのまま返す
    if (imageData.length <= targetSize) {
      developer.log('Image size is optimal, no compression needed', name: 'ImageService');
      return imageData;
    }
    
    // 10MB以上の場合でも圧縮を試みる
    if (imageData.length > maxSize * 2) {
      // 20MB以上は流石に大きすぎる
      developer.log(
        'Image too large to process: ${(imageData.length / 1024 / 1024).toStringAsFixed(2)} MB',
        name: 'ImageService',
      );
      throw Exception('画像が大きすぎます（${(imageData.length / 1024 / 1024).toStringAsFixed(1)}MB）。20MB以下の画像を選択してください。');
    }
    
    // Web環境で実際の画像圧縮を実行
    try {
      developer.log('Starting image compression...', name: 'ImageService');
      
      if (kIsWeb) {
        // Web環境では Canvas API を使った圧縮を実行
        final compressedData = await ImageCompressorWeb.compressImage(
          imageData: imageData,
          fileName: fileName,
          maxWidth: 1920,
          maxHeight: 1920,
          quality: 85, // 初期品質85%から開始
          targetSizeBytes: targetSize,
        );
        
        developer.log(
          'Compression complete: ${(imageData.length / 1024 / 1024).toStringAsFixed(2)}MB -> ${(compressedData.length / 1024 / 1024).toStringAsFixed(2)}MB',
          name: 'ImageService',
        );
        
        return compressedData;
      } else {
        // Web以外の環境では元の画像を返す
        developer.log('Non-web platform, returning original image', name: 'ImageService');
        return imageData;
      }
      
    } catch (e) {
      developer.log('Compression failed: $e', name: 'ImageService', error: e);
      // 圧縮に失敗した場合は元の画像を使用（ただし10MB以下の場合のみ）
      if (imageData.length <= maxSize) {
        return imageData;
      } else {
        throw Exception('画像の圧縮に失敗しました。より小さい画像を選択してください。');
      }
    }
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
    if (_storage == null) {
      return null;
    }
    
    try {
      final tenantId = await _getTenantId();
      // temp_IDの場合は一時フォルダにアップロード
      final path = serviceId.startsWith('temp_') 
          ? 'tenants/$tenantId/temp/$serviceId/$imageId'
          : 'tenants/$tenantId/services/$serviceId/$imageId';
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
      
      developer.log('Image uploaded to Firebase: $url', name: 'ImageService');
      return url;
    } catch (e) {
      developer.log('Error uploading to Firebase Storage: $e', name: 'ImageService', error: e);
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
    if (_storage == null) {
      developer.log('Firebase Storage is not initialized, cannot delete', name: 'ImageService');
      return;
    }
    
    try {
      developer.log('Deleting image from Firebase Storage: $url', name: 'ImageService');
      final ref = _storage!.refFromURL(url);
      await ref.delete();
      developer.log('Image deleted successfully from Firebase Storage: $url', name: 'ImageService');
    } catch (e) {
      developer.log('Error deleting from Firebase Storage: $e\nURL: $url', name: 'ImageService', error: e);
      // エラーが発生しても処理を続行
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
  
  // テナントIDを取得（AuthServiceから取得）
  Future<String> _getTenantId() async {
    // 現在のユーザーのUIDをテナントIDとして使用
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }
    // ユーザーがログインしていない場合はエラー
    throw Exception('User not authenticated - cannot upload images');
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
    developer.log('=== DELETING ALL IMAGES FOR SERVICE: $serviceId ===', name: 'ImageService');
    
    // 1. LocalStorageから画像情報を取得
    final images = await getServiceImages(serviceId);
    developer.log('Found ${images.length} images to delete from LocalStorage', name: 'ImageService');
    
    // 2. Firebase Storageから直接フォルダ内のすべての画像を削除
    if (_storage != null) {
      try {
        final tenantId = await _getTenantId();
        final folderPath = 'tenants/$tenantId/services/$serviceId';
        developer.log('Attempting to delete all files in folder: $folderPath', name: 'ImageService');
        
        // フォルダ内のすべてのファイルをリスト
        final listResult = await _storage!.ref(folderPath).listAll();
        developer.log('Found ${listResult.items.length} files in Firebase Storage folder', name: 'ImageService');
        
        // すべてのファイルを削除
        final deletionFutures = <Future<void>>[];
        for (final item in listResult.items) {
          developer.log('Deleting file: ${item.fullPath}', name: 'ImageService');
          deletionFutures.add(item.delete());
        }
        
        if (deletionFutures.isNotEmpty) {
          await Future.wait(deletionFutures);
          developer.log('Deleted ${deletionFutures.length} files from Firebase Storage', name: 'ImageService');
        }
      } catch (e) {
        developer.log('Error deleting folder from Firebase Storage: $e', name: 'ImageService', error: e);
      }
    }
    
    // 3. LocalStorageから画像データを削除
    _imageCache.remove(serviceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_localStoragePrefix$serviceId');
    developer.log('Removed images from LocalStorage', name: 'ImageService');
    
    // 4. URLベースでも削除（バックアップ）
    for (final image in images) {
      if (image.firebaseUrl.isNotEmpty) {
        try {
          await _deleteFromFirebase(image.firebaseUrl);
        } catch (e) {
          // URLベースの削除が失敗しても続行
          developer.log('Failed to delete by URL: ${image.firebaseUrl}', name: 'ImageService');
        }
      }
    }
    
    developer.log('=== COMPLETED DELETING ALL IMAGES ===', name: 'ImageService');
    notifyListeners();
  }
  
  // 一時IDから実際のサービスIDに画像を移動
  Future<void> moveImages(String fromServiceId, String toServiceId) async {
    if (fromServiceId == toServiceId) return;
    
    // 一時IDの画像を取得
    final tempImages = await getServiceImages(fromServiceId);
    if (tempImages.isEmpty) return;
    
    developer.log('Moving ${tempImages.length} images from $fromServiceId to $toServiceId', name: 'ImageService');
    
    // Firebase Storage内でファイルをコピー（新しいURLを生成）
    final List<ServiceImage> newImages = [];
    for (final img in tempImages) {
      ServiceImage newImage;
      
      // Firebase URLがある場合はコピーして新しいURLを取得
      if (img.firebaseUrl.isNotEmpty && img.localData.isNotEmpty) {
        // ローカルデータがある場合は再アップロード
        final newUrl = await _uploadToFirebase(
          img.id,
          toServiceId,
          img.imageBytes,
          img.fileName,
        );
        
        newImage = ServiceImage(
          id: img.id,
          serviceId: toServiceId,
          localData: img.localData,
          firebaseUrl: newUrl ?? img.firebaseUrl,
          fileName: img.fileName,
          uploadedAt: img.uploadedAt,
          size: img.size,
        );
      } else {
        // Firebase URLのみまたはローカルデータのみの場合はそのまま使用
        newImage = ServiceImage(
          id: img.id,
          serviceId: toServiceId,
          localData: img.localData,
          firebaseUrl: img.firebaseUrl,
          fileName: img.fileName,
          uploadedAt: img.uploadedAt,
          size: img.size,
        );
      }
      
      newImages.add(newImage);
    }
    
    // 新しいサービスIDで画像を保存
    _imageCache[toServiceId] = newImages;
    
    // LocalStorageに保存
    await _saveToLocalStorage(toServiceId);
    
    // 一時IDのデータを削除
    _imageCache.remove(fromServiceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_localStoragePrefix$fromServiceId');
    
    // tempフォルダの画像を削除
    if (fromServiceId.startsWith('temp_')) {
      await _deleteTempFolder(fromServiceId);
    }
    
    notifyListeners();
  }
  
  // tempフォルダを削除
  Future<void> _deleteTempFolder(String tempServiceId) async {
    if (_storage == null) return;
    
    try {
      final tenantId = await _getTenantId();
      final tempPath = 'tenants/$tenantId/temp/$tempServiceId';
      developer.log('Deleting temp folder: $tempPath', name: 'ImageService');
      
      final listResult = await _storage!.ref(tempPath).listAll();
      final deletionFutures = <Future<void>>[];
      
      for (final item in listResult.items) {
        developer.log('Deleting temp file: ${item.fullPath}', name: 'ImageService');
        deletionFutures.add(item.delete());
      }
      
      if (deletionFutures.isNotEmpty) {
        await Future.wait(deletionFutures);
        developer.log('Deleted ${deletionFutures.length} temp files', name: 'ImageService');
      }
    } catch (e) {
      developer.log('Error deleting temp folder: $e', name: 'ImageService', error: e);
    }
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
  Uint8List get imageBytes {
    if (localData.isNotEmpty) {
      return base64Decode(localData);
    }
    // LocalDataが空の場合はダミーデータを返す（実際にはFirebaseから取得すべき）
    return Uint8List.fromList([]);
  }
  
  // ファイルサイズを人間が読みやすい形式で取得
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}