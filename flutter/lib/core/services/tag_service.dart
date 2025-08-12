import 'package:flutter/material.dart';

class TagService extends ChangeNotifier {
  // ユーザーごとのタグを管理
  final Map<String, List<String>> _userTags = {};
  
  // 利用可能なタグのプリセット
  final List<TagPreset> availableTags = [
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

  // ユーザーのタグを取得
  List<String> getUserTags(String userId) {
    return _userTags[userId] ?? [];
  }

  // タグを追加
  void addTag(String userId, String tag) {
    if (!_userTags.containsKey(userId)) {
      _userTags[userId] = [];
    }
    if (!_userTags[userId]!.contains(tag)) {
      _userTags[userId]!.add(tag);
      notifyListeners();
    }
  }

  // タグを削除
  void removeTag(String userId, String tag) {
    if (_userTags.containsKey(userId)) {
      _userTags[userId]!.remove(tag);
      if (_userTags[userId]!.isEmpty) {
        _userTags.remove(userId);
      }
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
  void toggleTag(String userId, String tag) {
    if (getUserTags(userId).contains(tag)) {
      removeTag(userId, tag);
    } else {
      addTag(userId, tag);
    }
  }

  // 複数のタグを一度に設定
  void setUserTags(String userId, List<String> tags) {
    _userTags[userId] = tags;
    notifyListeners();
  }

  // カスタムタグを追加（ユーザーが新しいタグを作成）
  void addCustomTag(String tagName, Color color) {
    if (!availableTags.any((tag) => tag.name == tagName)) {
      availableTags.add(TagPreset(name: tagName, color: color));
      notifyListeners();
    }
  }
}

class TagPreset {
  final String name;
  final Color color;

  TagPreset({required this.name, required this.color});
}