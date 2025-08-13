import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeColorKey = 'theme_color';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';
  
  // デフォルトカラー（現在の青緑色）
  static const Color defaultColor = Color(0xFF5D9B9B);
  
  // カラープリセット
  static const Map<String, ThemePreset> colorPresets = {
    'sakana': ThemePreset(
      name: 'SAKANA（デフォルト）',
      color: Color(0xFF5D9B9B),
      icon: Icons.water,
    ),
    'mint': ThemePreset(
      name: 'ミントグリーン（オリジナル）',
      color: Color(0xFFA8D8D0),
      icon: Icons.eco,
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
  
  // フォントサイズ設定（各サイズを1px単位で設定可能）
  static const Map<String, Map<String, double>> defaultFontSizes = {
    'xs': {  // 極小
      'body': 11,
      'button': 12,
      'caption': 10,
      'headline': 18,
      'title': 14,
      'subtitle': 12,
    },
    's': {   // 小
      'body': 13,
      'button': 14,
      'caption': 11,
      'headline': 20,
      'title': 16,
      'subtitle': 14,
    },
    'm': {   // 中（デフォルト）
      'body': 14,
      'button': 15,
      'caption': 12,
      'headline': 24,
      'title': 18,
      'subtitle': 16,
    },
    'l': {   // 大
      'body': 16,
      'button': 17,
      'caption': 14,
      'headline': 28,
      'title': 22,
      'subtitle': 18,
    },
  };
  
  // フォントファミリー設定（日本語フォント中心）
  static const Map<String, FontPreset> fontPresets = {
    // 日本語フォント（メイン）
    'mplus_rounded': FontPreset(name: 'M PLUS Rounded 1c', category: 'japanese', googleFont: 'M+PLUS+Rounded+1c'),
    'noto_sans_jp': FontPreset(name: 'Noto Sans JP', category: 'japanese', googleFont: 'Noto+Sans+JP'),
    'kosugi_maru': FontPreset(name: 'Kosugi Maru', category: 'japanese', googleFont: 'Kosugi+Maru'),
    'sawarabi_gothic': FontPreset(name: 'Sawarabi Gothic', category: 'japanese', googleFont: 'Sawarabi+Gothic'),
    'mplus_1p': FontPreset(name: 'M PLUS 1p', category: 'japanese', googleFont: 'M+PLUS+1p'),
    'zen_maru': FontPreset(name: 'Zen Maru Gothic', category: 'japanese', googleFont: 'Zen+Maru+Gothic'),
    'zen_kaku': FontPreset(name: 'Zen Kaku Gothic', category: 'japanese', googleFont: 'Zen+Kaku+Gothic+New'),
    'kiwi_maru': FontPreset(name: 'Kiwi Maru', category: 'japanese', googleFont: 'Kiwi+Maru'),
    'hachi_maru': FontPreset(name: 'Hachi Maru Pop', category: 'japanese', googleFont: 'Hachi+Maru+Pop'),
    'yusei_magic': FontPreset(name: 'Yusei Magic', category: 'japanese', googleFont: 'Yusei+Magic'),
    'shippori_mincho': FontPreset(name: 'Shippori Mincho', category: 'japanese', googleFont: 'Shippori+Mincho'),
    'kaisei_decol': FontPreset(name: 'Kaisei Decol', category: 'japanese', googleFont: 'Kaisei+Decol'),
    'reggae_one': FontPreset(name: 'Reggae One', category: 'japanese', googleFont: 'Reggae+One'),
    'rocknroll_one': FontPreset(name: 'RocknRoll One', category: 'japanese', googleFont: 'RocknRoll+One'),
    'stick': FontPreset(name: 'Stick', category: 'japanese', googleFont: 'Stick'),
    
    // 日本語対応のシンプルフォント（追加推奨）
    'noto_serif_jp': FontPreset(name: 'Noto Serif JP', category: 'japanese_serif', googleFont: 'Noto+Serif+JP'),
    'murecho': FontPreset(name: 'Murecho', category: 'japanese', googleFont: 'Murecho'),
    'rampart_one': FontPreset(name: 'Rampart One', category: 'japanese_design', googleFont: 'Rampart+One'),
    'dotgothic': FontPreset(name: 'DotGothic16', category: 'japanese_design', googleFont: 'DotGothic16'),
    'potta_one': FontPreset(name: 'Potta One', category: 'japanese_design', googleFont: 'Potta+One'),
    'dela_gothic': FontPreset(name: 'Dela Gothic One', category: 'japanese_design', googleFont: 'Dela+Gothic+One'),
    'train_one': FontPreset(name: 'Train One', category: 'japanese_design', googleFont: 'Train+One'),
    
    // 欧文フォント（最小限）
    'roboto': FontPreset(name: 'Roboto', category: 'standard', googleFont: 'Roboto'),
    'inter': FontPreset(name: 'Inter', category: 'standard', googleFont: 'Inter'),
    'nunito': FontPreset(name: 'Nunito', category: 'standard', googleFont: 'Nunito'),
  };

  Color _primaryColor = defaultColor;
  bool _isDarkMode = false;
  String _fontFamily = 'M PLUS Rounded 1c';
  String _fontSize = 'm';
  Map<String, double> _customFontSizes = {};
  SharedPreferences? _prefs;

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  String get fontFamily => _fontFamily;
  String get fontSize => _fontSize;
  
  // 各サイズ種別のフォントサイズを取得
  double getFontSize(String type) {
    // カスタムサイズがあればそれを使用
    final customKey = '${_fontSize}_$type';
    if (_customFontSizes.containsKey(customKey)) {
      return _customFontSizes[customKey]!;
    }
    // デフォルトサイズを使用
    return defaultFontSizes[_fontSize]?[type] ?? 14;
  }
  
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
    _fontFamily = _prefs?.getString(_fontFamilyKey) ?? 'M PLUS Rounded 1c';
    _fontSize = _prefs?.getString(_fontSizeKey) ?? 'm';
    
    // カスタムフォントサイズを読み込み
    final customSizesJson = _prefs?.getString('custom_font_sizes');
    if (customSizesJson != null) {
      final decoded = Map<String, dynamic>.from(json.decode(customSizesJson));
      _customFontSizes = decoded.map((key, value) => MapEntry(key, value.toDouble()));
    }
    
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

  // フォントファミリーの変更
  Future<void> setFontFamily(String fontFamily) async {
    print('ThemeService: フォント変更 $_fontFamily -> $fontFamily');
    _fontFamily = fontFamily;
    await _prefs?.setString(_fontFamilyKey, fontFamily);
    notifyListeners();
    print('ThemeService: notifyListeners() 呼び出し完了');
  }
  
  // フォントサイズの変更
  Future<void> setFontSize(String size) async {
    _fontSize = size;
    await _prefs?.setString(_fontSizeKey, size);
    notifyListeners();
  }
  
  // 特定タイプのカスタムフォントサイズを設定
  Future<void> setCustomFontSize(String sizeCategory, String type, double size) async {
    final key = '${sizeCategory}_$type';
    _customFontSizes[key] = size;
    await _prefs?.setString('custom_font_sizes', json.encode(_customFontSizes));
    notifyListeners();
  }
  
  // デフォルトに戻す
  Future<void> resetToDefault() async {
    _primaryColor = defaultColor;
    _isDarkMode = false;
    _fontFamily = 'M PLUS Rounded 1c';
    _fontSize = 'm';
    
    await _prefs?.remove(_themeColorKey);
    await _prefs?.remove(_isDarkModeKey);
    await _prefs?.remove(_fontFamilyKey);
    await _prefs?.remove(_fontSizeKey);
    
    notifyListeners();
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

  // Google Fontsからテキストスタイルを取得
  TextStyle _getGoogleFontStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
    
    // フォント名に基づいてGoogle Fontsのスタイルを適用
    switch (_fontFamily) {
      // 日本語フォント
      case 'M PLUS Rounded 1c':
        return GoogleFonts.mPlusRounded1c(textStyle: baseStyle);
      case 'Noto Sans JP':
        return GoogleFonts.notoSansJp(textStyle: baseStyle);
      case 'Kosugi Maru':
        return GoogleFonts.kosugiMaru(textStyle: baseStyle);
      case 'Sawarabi Gothic':
        return GoogleFonts.sawarabiGothic(textStyle: baseStyle);
      case 'M PLUS 1p':
        return GoogleFonts.mPlus1p(textStyle: baseStyle);
      case 'Zen Maru Gothic':
        return GoogleFonts.zenMaruGothic(textStyle: baseStyle);
      case 'Zen Kaku Gothic New':
        return GoogleFonts.zenKakuGothicNew(textStyle: baseStyle);
      case 'Kiwi Maru':
        return GoogleFonts.kiwiMaru(textStyle: baseStyle);
      case 'Hachi Maru Pop':
        return GoogleFonts.hachiMaruPop(textStyle: baseStyle);
      case 'Yusei Magic':
        return GoogleFonts.yuseiMagic(textStyle: baseStyle);
      case 'Shippori Mincho':
        return GoogleFonts.shipporiMincho(textStyle: baseStyle);
      case 'Kaisei Decol':
        return GoogleFonts.kaiseiDecol(textStyle: baseStyle);
      case 'Reggae One':
        return GoogleFonts.reggaeOne(textStyle: baseStyle);
      case 'RocknRoll One':
        return GoogleFonts.rocknRollOne(textStyle: baseStyle);
      case 'Stick':
        return GoogleFonts.stick(textStyle: baseStyle);
      
      // 日本語対応のシンプルフォント  
      case 'Noto Serif JP':
        return GoogleFonts.notoSerifJp(textStyle: baseStyle);
      case 'Murecho':
        return GoogleFonts.murecho(textStyle: baseStyle);
      case 'Rampart One':
        return GoogleFonts.rampartOne(textStyle: baseStyle);
      case 'DotGothic16':
        return GoogleFonts.dotGothic16(textStyle: baseStyle);
      case 'Potta One':
        return GoogleFonts.pottaOne(textStyle: baseStyle);
      case 'Dela Gothic One':
        return GoogleFonts.delaGothicOne(textStyle: baseStyle);
      case 'Train One':
        return GoogleFonts.trainOne(textStyle: baseStyle);
      
      // スタンダードフォント（最小限）
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: baseStyle);
      case 'Inter':
        return GoogleFonts.inter(textStyle: baseStyle);
      case 'Nunito':
        return GoogleFonts.nunito(textStyle: baseStyle);
      
      default:
        return GoogleFonts.mPlusRounded1c(textStyle: baseStyle);
    }
  }

  // 現在のテーマデータを生成
  ThemeData generateThemeData() {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    // ダークモードの背景色を設定
    final scaffoldColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    
    return baseTheme.copyWith(
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: scaffoldColor,
      cardColor: cardColor,
      textTheme: TextTheme(
        // Display styles (大きなタイトル用)
        displayLarge: _getGoogleFontStyle(fontSize: getFontSize('headline') * 1.5, fontWeight: FontWeight.bold),
        displayMedium: _getGoogleFontStyle(fontSize: getFontSize('headline') * 1.2, fontWeight: FontWeight.bold),
        displaySmall: _getGoogleFontStyle(fontSize: getFontSize('headline'), fontWeight: FontWeight.bold),
        // Headline styles
        headlineLarge: _getGoogleFontStyle(fontSize: getFontSize('headline'), fontWeight: FontWeight.bold),
        headlineMedium: _getGoogleFontStyle(fontSize: getFontSize('title'), fontWeight: FontWeight.w600),
        headlineSmall: _getGoogleFontStyle(fontSize: getFontSize('subtitle'), fontWeight: FontWeight.w500),
        // Title styles
        titleLarge: _getGoogleFontStyle(fontSize: getFontSize('title'), fontWeight: FontWeight.w600),
        titleMedium: _getGoogleFontStyle(fontSize: getFontSize('subtitle'), fontWeight: FontWeight.w500),
        titleSmall: _getGoogleFontStyle(fontSize: getFontSize('caption'), fontWeight: FontWeight.w500),
        // Body styles
        bodyLarge: _getGoogleFontStyle(fontSize: getFontSize('body')),
        bodyMedium: _getGoogleFontStyle(fontSize: getFontSize('body')),
        bodySmall: _getGoogleFontStyle(fontSize: getFontSize('caption')),
        // Label styles
        labelLarge: _getGoogleFontStyle(fontSize: getFontSize('button'), fontWeight: FontWeight.w500),
        labelMedium: _getGoogleFontStyle(fontSize: getFontSize('caption')),
        labelSmall: _getGoogleFontStyle(fontSize: getFontSize('caption') - 2),
      ),
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
          textStyle: _getGoogleFontStyle(),
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

// フォントプリセットクラス
class FontPreset {
  final String name;
  final String category;
  final String googleFont;

  const FontPreset({
    required this.name,
    required this.category,
    required this.googleFont,
  });
}