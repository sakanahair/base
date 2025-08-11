import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeColorKey = 'theme_color';
  static const String _isDarkModeKey = 'is_dark_mode';
  
  // デフォルトカラー（現在の青緑色）
  static const Color defaultColor = Color(0xFF5D9B9B);
  
  // カラープリセット
  static const Map<String, ThemePreset> colorPresets = {
    'sakana': ThemePreset(
      name: 'SAKANA（デフォルト）',
      color: Color(0xFF5D9B9B),
      icon: Icons.water,
    ),
    'line': ThemePreset(
      name: 'LINE',
      color: Color(0xFF00B900),
      icon: Icons.chat_bubble,
    ),
    'instagram': ThemePreset(
      name: 'Instagram',
      color: Color(0xFFE4405F),
      icon: Icons.camera_alt,
    ),
    'twitter': ThemePreset(
      name: 'Twitter',
      color: Color(0xFF1DA1F2),
      icon: Icons.alternate_email,
    ),
    'youtube': ThemePreset(
      name: 'YouTube',
      color: Color(0xFFFF0000),
      icon: Icons.play_circle,
    ),
    'purple': ThemePreset(
      name: 'エレガント',
      color: Color(0xFF9B59B6),
      icon: Icons.diamond,
    ),
    'gold': ThemePreset(
      name: 'ゴールド',
      color: Color(0xFFFFD700),
      icon: Icons.star,
    ),
    'minimal': ThemePreset(
      name: 'ミニマル',
      color: Color(0xFF2C3E50),
      icon: Icons.square,
    ),
  };

  Color _primaryColor = defaultColor;
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  
  // 明るい色バリエーション
  Color get primaryColorLight => Color.lerp(_primaryColor, Colors.white, 0.2)!;
  
  // 暗い色バリエーション
  Color get primaryColorDark => Color.lerp(_primaryColor, Colors.black, 0.2)!;
  
  // テキストカラー（コントラスト自動判定）
  Color get onPrimaryColor {
    final luminance = _primaryColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  // 背景用の薄い色
  Color get primaryColorBackground => _primaryColor.withOpacity(0.05);
  
  // ホバー用の色
  Color get primaryColorHover => _primaryColor.withOpacity(0.1);

  ThemeService() {
    _loadTheme();
  }

  // テーマの読み込み
  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    
    final colorValue = _prefs?.getInt(_themeColorKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    
    _isDarkMode = _prefs?.getBool(_isDarkModeKey) ?? false;
    
    notifyListeners();
  }

  // プライマリカラーの変更
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _prefs?.setInt(_themeColorKey, color.value);
    notifyListeners();
  }

  // プリセットから選択
  Future<void> setPresetColor(String presetKey) async {
    final preset = colorPresets[presetKey];
    if (preset != null) {
      await setPrimaryColor(preset.color);
    }
  }

  // ダークモードの切り替え
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool(_isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  // デフォルトに戻す
  Future<void> resetToDefault() async {
    await setPrimaryColor(defaultColor);
    _isDarkMode = false;
    await _prefs?.setBool(_isDarkModeKey, false);
  }

  // カスタムカラーの検証
  bool isValidColor(String hexColor) {
    if (!hexColor.startsWith('#')) return false;
    if (hexColor.length != 7) return false;
    
    try {
      int.parse(hexColor.substring(1), radix: 16);
      return true;
    } catch (_) {
      return false;
    }
  }

  // HEXカラーからColorオブジェクトを作成
  Color? colorFromHex(String hexColor) {
    if (!isValidColor(hexColor)) return null;
    
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  // 現在のテーマデータを生成
  ThemeData generateThemeData() {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: onPrimaryColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _primaryColor,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: onPrimaryColor);
          }
          return IconThemeData(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _primaryColor,
      ),
    );
  }
}

// テーマプリセットクラス
class ThemePreset {
  final String name;
  final Color color;
  final IconData icon;

  const ThemePreset({
    required this.name,
    required this.color,
    required this.icon,
  });
}