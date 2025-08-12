import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hybrid_cache_service.dart';

class TagService extends ChangeNotifier {
  // ユーザーごとのタグを管理（ローカルキャッシュ）
  final Map<String, List<String>> _userTags = {};
  
  // 利用可能なタグのプリセット
  final List<TagPreset> availableTags = [
    TagPreset(name: '顧客', color: Colors.blue[700]!),
    TagPreset(name: 'VIP', color: Colors.amber[700]!),
    TagPreset(name: '新規', color: Colors.green[600]!),
    TagPreset(name: '常連', color: Colors.blue[600]!),
    TagPreset(name: '休眠', color: Colors.grey[600]!),
    TagPreset(name: '要フォロー', color: Colors.red[600]!),
    TagPreset(name: 'カラー', color: Colors.purple[600]!),
    TagPreset(name: 'パーマ', color: Colors.orange[600]!),
    TagPreset(name: 'トリートメント', color: Colors.teal[600]!),
    TagPreset(name: 'カット', color: Colors.indigo[600]!),
    TagPreset(name: '学生', color: Colors.cyan[600]!),
    TagPreset(name: 'シニア', color: Colors.brown[600]!),
    TagPreset(name: '紹介', color: Colors.pink[600]!),
    TagPreset(name: 'クレーム対応', color: Colors.deepOrange[600]!),
    TagPreset(name: '予約頻度高', color: Colors.lightGreen[600]!),
    TagPreset(name: '単価高', color: Colors.deepPurple[600]!),
  ];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _storageKey = 'sakana_tags';
  static const String _presetsKey = 'sakana_tag_presets';
  
  TagService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // LocalStorageから読み込み
    await _loadFromLocalStorage();
    // Firebaseと同期
    _syncWithFirebase();
  }
  
  // LocalStorageから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ユーザータグを読み込み
      final String? tagsJson = prefs.getString(_storageKey);
      if (tagsJson != null && tagsJson.isNotEmpty) {
        final Map<String, dynamic> tagsMap = json.decode(tagsJson);
        _userTags.clear();
        tagsMap.forEach((key, value) {
          _userTags[key] = List<String>.from(value);
        });
      }
      
      // カスタムプリセットを読み込み
      final String? presetsJson = prefs.getString(_presetsKey);
      if (presetsJson != null && presetsJson.isNotEmpty) {
        final List<dynamic> presetsList = json.decode(presetsJson);
        for (final preset in presetsList) {
          final name = preset['name'];
          // デフォルトにないカスタムタグのみ追加
          if (!availableTags.any((tag) => tag.name == name)) {
            availableTags.add(TagPreset(
              name: name,
              color: Color(preset['color']),
            ));
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading tags from LocalStorage: $e');
    }
  }
  
  // LocalStorageに保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ユーザータグを保存
      final String tagsJson = json.encode(_userTags);
      await prefs.setString(_storageKey, tagsJson);
      
      // カスタムプリセットのみ保存（デフォルト16個以降）
      final customPresets = availableTags.skip(16).map((preset) => {
        'name': preset.name,
        'color': preset.color.value,
      }).toList();
      
      if (customPresets.isNotEmpty) {
        final String presetsJson = json.encode(customPresets);
        await prefs.setString(_presetsKey, presetsJson);
      }
    } catch (e) {
      print('Error saving tags to LocalStorage: $e');
    }
  }
  
  // Firebaseと同期
  Future<void> _syncWithFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // カスタムタグプリセットを同期
      final presetsDoc = await _firestore
          .collection('tagPresets')
          .doc(user.uid)
          .get();
      
      if (presetsDoc.exists) {
        final data = presetsDoc.data()!;
        final customTags = data['customTags'] as List<dynamic>? ?? [];
        
        for (final tag in customTags) {
          final name = tag['name'];
          if (!availableTags.any((t) => t.name == name)) {
            availableTags.add(TagPreset(
              name: name,
              color: Color(tag['color']),
            ));
          }
        }
      }
      
      // ユーザータグをリアルタイム同期
      _firestore
          .collection('userTags')
          .where('tenantId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final userId = data['userId'] as String;
          final tags = List<String>.from(data['tags'] ?? []);
          _userTags[userId] = tags;
        }
        _saveToLocalStorage();
        notifyListeners();
      });
    } catch (e) {
      print('Error syncing tags with Firebase: $e');
    }
  }
  
  // Firebaseに保存
  Future<void> _saveToFirebase(String userId, List<String> tags) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('userTags')
          .doc('${user.uid}_$userId')
          .set({
        'tenantId': user.uid,
        'userId': userId,
        'tags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving tags to Firebase: $e');
    }
  }
  
  // カスタムタグプリセットをFirebaseに保存
  Future<void> _savePresetsToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // カスタムプリセットのみ（デフォルト16個以降）
      final customPresets = availableTags.skip(16).map((preset) => {
        'name': preset.name,
        'color': preset.color.value,
      }).toList();
      
      await _firestore
          .collection('tagPresets')
          .doc(user.uid)
          .set({
        'tenantId': user.uid,
        'customTags': customPresets,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving presets to Firebase: $e');
    }
  }

  // ユーザーのタグを取得
  List<String> getUserTags(String userId) {
    return _userTags[userId] ?? [];
  }

  // タグを追加
  Future<void> addTag(String userId, String tag) async {
    if (!_userTags.containsKey(userId)) {
      _userTags[userId] = [];
    }
    if (!_userTags[userId]!.contains(tag)) {
      _userTags[userId]!.add(tag);
      await _saveToLocalStorage();
      await _saveToFirebase(userId, _userTags[userId]!);
      notifyListeners();
    }
  }

  // タグを削除
  Future<void> removeTag(String userId, String tag) async {
    if (_userTags.containsKey(userId)) {
      _userTags[userId]!.remove(tag);
      if (_userTags[userId]!.isEmpty) {
        _userTags.remove(userId);
        await _firestore
            .collection('userTags')
            .doc('${_auth.currentUser?.uid}_$userId')
            .delete();
      } else {
        await _saveToFirebase(userId, _userTags[userId]!);
      }
      await _saveToLocalStorage();
      notifyListeners();
    }
  }

  // タグの色を取得
  Color getTagColor(String tag) {
    final preset = availableTags.firstWhere(
      (p) => p.name == tag,
      orElse: () => TagPreset(name: tag, color: Colors.grey[600]!),
    );
    return preset.color;
  }

  // タグをトグル（追加/削除）
  Future<void> toggleTag(String userId, String tag) async {
    if (getUserTags(userId).contains(tag)) {
      await removeTag(userId, tag);
    } else {
      await addTag(userId, tag);
    }
  }

  // 複数のタグを一度に設定
  Future<void> setUserTags(String userId, List<String> tags) async {
    _userTags[userId] = tags;
    await _saveToLocalStorage();
    await _saveToFirebase(userId, tags);
    notifyListeners();
  }

  // カスタムタグを追加（ユーザーが新しいタグを作成）
  Future<void> addCustomTag(String tagName, Color color) async {
    if (!availableTags.any((tag) => tag.name == tagName)) {
      availableTags.add(TagPreset(name: tagName, color: color));
      await _saveToLocalStorage();
      await _savePresetsToFirebase();
      notifyListeners();
    }
  }
  
  // 全ユーザーのタグ情報を取得（使用中のタグ一覧取得用）
  Set<String> getAllUsedTags() {
    final Set<String> usedTags = {};
    _userTags.values.forEach((tags) {
      usedTags.addAll(tags);
    });
    return usedTags;
  }
}

class TagPreset {
  final String name;
  final Color color;

  TagPreset({required this.name, required this.color});
}