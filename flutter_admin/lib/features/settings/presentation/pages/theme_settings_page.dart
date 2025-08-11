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
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
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
                    color: isSelected ? preset.color : AppTheme.textPrimary,
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
              subtitle: const Text('テーマカラーを初期状態に戻します'),
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

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }
}