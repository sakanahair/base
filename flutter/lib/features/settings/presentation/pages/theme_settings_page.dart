import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  final TextEditingController _hexController = TextEditingController();
  Color _customColor = ThemeService.defaultColor;

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('テーマカラー設定'),
        backgroundColor: themeService.primaryColor,
        foregroundColor: themeService.onPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プリセットカラー
            _buildSection(
              title: 'プリセットカラー',
              subtitle: 'お好みのテーマカラーを選択してください',
              child: _buildPresetColors(themeService),
            ),
            
            const SizedBox(height: 32),
            
            // カスタムカラー
            _buildSection(
              title: 'カスタムカラー',
              subtitle: 'ブランドカラーを自由に設定できます',
              child: _buildCustomColorPicker(themeService),
            ),
            
            const SizedBox(height: 32),
            
            // プレビュー
            _buildSection(
              title: 'プレビュー',
              subtitle: '選択したカラーの表示確認',
              child: _buildPreview(themeService),
            ),
            
            const SizedBox(height: 32),
            
            // フォント設定
            _buildSection(
              title: 'フォント設定',
              subtitle: 'フォントファミリーとサイズを選択',
              child: _buildFontSettings(themeService),
            ),
            
            const SizedBox(height: 32),
            
            // その他の設定
            _buildSection(
              title: 'その他の設定',
              subtitle: '表示モードの切り替え',
              child: _buildOtherSettings(themeService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildPresetColors(ThemeService themeService) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: ThemeService.colorPresets.length,
      itemBuilder: (context, index) {
        final key = ThemeService.colorPresets.keys.elementAt(index);
        final preset = ThemeService.colorPresets[key]!;
        final isSelected = themeService.primaryColor == preset.color;
        
        return InkWell(
          onTap: () => themeService.setPresetColor(key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? preset.color 
                    : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    preset.icon,
                    color: preset.color.computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  preset.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? preset.color : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildCustomColorPicker(ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // カラーピッカー
            ColorPicker(
              color: _customColor,
              onColorChanged: (Color color) {
                setState(() {
                  _customColor = color;
                  _hexController.text = '#${color.hex}';
                });
              },
              pickersEnabled: const {
                ColorPickerType.wheel: true,
                ColorPickerType.accent: false,
                ColorPickerType.primary: false,
              },
              width: 44,
              height: 44,
              borderRadius: 22,
              heading: const Text('カラーホイール'),
            ),
            
            const SizedBox(height: 16),
            
            // HEX入力
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: InputDecoration(
                      labelText: 'HEXコード',
                      hintText: '#5D9B9B',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.color_lens),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste),
                        onPressed: () async {
                          // クリップボードから貼り付け
                        },
                      ),
                    ),
                    onChanged: (value) {
                      final color = themeService.colorFromHex(value);
                      if (color != null) {
                        setState(() {
                          _customColor = color;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    themeService.setPrimaryColor(_customColor);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('カスタムカラーを適用しました'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _customColor,
                    foregroundColor: _customColor.computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                  child: const Text('適用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 現在のフォント情報表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '現在のフォント: ${themeService.fontFamily}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // フォントプレビューテキスト
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'あいうえお かきくけこ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: themeService.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ABCDEFG 12345',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: themeService.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'このフォントで表示されています',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: themeService.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // ボタンプレビュー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColor,
                    foregroundColor: themeService.onPrimaryColor,
                  ),
                  child: const Text('プライマリ'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColorLight,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('ライト'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColorDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ダーク'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // プログレスバー
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: themeService.primaryColorBackground,
              valueColor: AlwaysStoppedAnimation(themeService.primaryColor),
            ),
            
            const SizedBox(height: 16),
            
            // スイッチとチェックボックス
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: themeService.primaryColor,
                ),
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: themeService.primaryColor,
                ),
                Radio(
                  value: true,
                  groupValue: true,
                  onChanged: (_) {},
                  activeColor: themeService.primaryColor,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite),
                  color: themeService.primaryColor,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // チップ
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('チップ'),
                  backgroundColor: themeService.primaryColorBackground,
                  labelStyle: TextStyle(color: themeService.primaryColor),
                ),
                Chip(
                  label: const Text('選択済み'),
                  backgroundColor: themeService.primaryColor,
                  labelStyle: TextStyle(color: themeService.onPrimaryColor),
                ),
                ActionChip(
                  label: const Text('アクション'),
                  onPressed: () {},
                  backgroundColor: themeService.primaryColorHover,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSettings(ThemeService themeService) {
    return Column(
      children: [
        // フォントサイズ選択
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'フォントサイズ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFontSizeButton(themeService, 'xs', '極小'),
                    _buildFontSizeButton(themeService, 's', '小'),
                    _buildFontSizeButton(themeService, 'm', '中'),
                    _buildFontSizeButton(themeService, 'l', '大'),
                  ],
                ),
                const SizedBox(height: 12),
                // 詳細サイズ設定ボタン
                TextButton.icon(
                  onPressed: () => _showDetailedFontSizeDialog(context, themeService),
                  icon: const Icon(Icons.tune),
                  label: const Text('詳細サイズ設定'),
                ),
                const SizedBox(height: 16),
                // プレビューテキスト
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'このテキストはプレビューです。現在のサイズ: ${
                      themeService.fontSize == 'xs' ? '極小' :
                      themeService.fontSize == 's' ? '小' :
                      themeService.fontSize == 'm' ? '中' : '大'
                    }',
                    style: TextStyle(
                      fontSize: themeService.getFontSize('body'),
                      fontFamily: themeService.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // フォントファミリー選択
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'フォントファミリー',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeService.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '現在: ${themeService.fontFamily}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeService.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 大きなプレビューボックス
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeService.primaryColor.withOpacity(0.05),
                        themeService.primaryColor.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeService.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'フォントプレビュー',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeService.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'あいうえお かきくけこ さしすせそ',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The quick brown fox jumps over the lazy dog',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1234567890 !@#\$%^&*()',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // ゴシック体フォント（標準）
                ExpansionTile(
                  title: const Text('ゴシック体（標準）'),
                  initiallyExpanded: true,
                  children: [
                    _buildFontGrid(
                      themeService,
                      ThemeService.fontPresets.entries
                        .where((e) => e.value.category == 'japanese')
                        .toList(),
                    ),
                  ],
                ),
                
                // 明朝体・ビジネスフォント
                ExpansionTile(
                  title: const Text('明朝体・ビジネス'),
                  children: [
                    _buildFontGrid(
                      themeService,
                      ThemeService.fontPresets.entries
                        .where((e) => e.value.category == 'japanese_serif' || e.value.category == 'japanese_business')
                        .toList(),
                    ),
                  ],
                ),
                
                // デザインフォント
                ExpansionTile(
                  title: const Text('デザイン・装飾'),
                  children: [
                    _buildFontGrid(
                      themeService,
                      ThemeService.fontPresets.entries
                        .where((e) => e.value.category == 'japanese_design')
                        .toList(),
                    ),
                  ],
                ),
                
                // 欧文フォント（オプション）
                ExpansionTile(
                  title: const Text('欧文フォント（補助）'),
                  children: [
                    _buildFontGrid(
                      themeService,
                      ThemeService.fontPresets.entries
                        .where((e) => e.value.category == 'standard')
                        .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFontSizeButton(ThemeService themeService, String size, String label) {
    final isSelected = themeService.fontSize == size;
    return InkWell(
      onTap: () => themeService.setFontSize(size),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? themeService.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? themeService.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? themeService.onPrimaryColor : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: ThemeService.defaultFontSizes[size]!['button']!,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFontGrid(
    ThemeService themeService,
    List<MapEntry<String, FontPreset>> fonts,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: fonts.length,
      itemBuilder: (context, index) {
        final font = fonts[index].value;
        final isSelected = themeService.fontFamily == font.name;
        
        return InkWell(
          onTap: () {
            print('フォント選択: ${font.name}');
            themeService.setFontFamily(font.name);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? themeService.primaryColorBackground : Colors.white,
              border: Border.all(
                color: isSelected ? themeService.primaryColor : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              font.name,
              style: TextStyle(
                fontFamily: font.name,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? themeService.primaryColor : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ).animate().fadeIn(delay: (index * 30).ms);
      },
    );
  }
  
  Widget _buildOtherSettings(ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ダークモード切り替え
            SwitchListTile(
              title: const Text('ダークモード'),
              subtitle: const Text('アプリ全体を暗い配色に変更します'),
              value: themeService.isDarkMode,
              onChanged: (_) => themeService.toggleDarkMode(),
              activeColor: themeService.primaryColor,
            ),
            
            const Divider(),
            
            // リセットボタン
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('デフォルトに戻す'),
              subtitle: const Text('テーマ・フォント設定を初期状態に戻します'),
              trailing: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認'),
                      content: const Text('テーマカラーをデフォルトに戻しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            themeService.resetToDefault();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('デフォルトカラーに戻しました'),
                              ),
                            );
                          },
                          child: const Text('リセット'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('リセット'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedFontSizeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('詳細フォントサイズ設定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在のサイズ: ${themeService.fontSize == 'xs' ? '極小' : themeService.fontSize == 's' ? '小' : themeService.fontSize == 'm' ? '中' : '大'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSizeSlider(context, themeService, 'body', '本文'),
              _buildSizeSlider(context, themeService, 'headline', '見出し'),
              _buildSizeSlider(context, themeService, 'title', 'タイトル'),
              _buildSizeSlider(context, themeService, 'subtitle', 'サブタイトル'),
              _buildSizeSlider(context, themeService, 'button', 'ボタン'),
              _buildSizeSlider(context, themeService, 'caption', 'キャプション'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // デフォルトにリセット
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSizeSlider(BuildContext context, ThemeService themeService, String type, String label) {
    final currentSize = themeService.getFontSize(type);
    return StatefulBuilder(
      builder: (context, setState) {
        double sliderValue = currentSize;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text('${sliderValue.toInt()}px'),
              ],
            ),
            Slider(
              value: sliderValue,
              min: 8,
              max: 32,
              divisions: 24,
              onChanged: (value) {
                setState(() {
                  sliderValue = value;
                });
                themeService.setCustomFontSize(themeService.fontSize, type, value);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }
}