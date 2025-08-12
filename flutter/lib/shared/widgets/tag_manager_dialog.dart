import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tag_service.dart';
import '../../core/theme/app_theme.dart';

class TagManagerDialog extends StatefulWidget {
  final String userId;
  final String userName;
  
  const TagManagerDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  final TextEditingController _customTagController = TextEditingController();
  Color _selectedColor = Colors.blue[600]!;
  
  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final tagService = Provider.of<TagService>(context);
    final userTags = tagService.getUserTags(widget.userId);
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('タグ管理'),
          const SizedBox(height: 4),
          Text(
            widget.userName,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現在のタグ
            if (userTags.isNotEmpty) ...[
              Text(
                '現在のタグ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: userTags.map((tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: tagService.getTagColor(tag),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: tagService.getTagColor(tag).withOpacity(0.15),
                  side: BorderSide(
                    color: tagService.getTagColor(tag).withOpacity(0.3),
                    width: 1,
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: tagService.getTagColor(tag),
                  ),
                  onDeleted: () {
                    tagService.removeTag(widget.userId, tag);
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // 利用可能なタグ
            Text(
              'タグを追加',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagService.availableTags.map((preset) {
                    final isSelected = userTags.contains(preset.name);
                    return FilterChip(
                      label: Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : preset.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: preset.color,
                      backgroundColor: preset.color.withOpacity(0.15),
                      side: BorderSide(
                        color: preset.color.withOpacity(0.3),
                        width: 1,
                      ),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        tagService.toggleTag(widget.userId, preset.name);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // カスタムタグ追加
            Text(
              'カスタムタグを作成',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    decoration: InputDecoration(
                      hintText: '新しいタグ名',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // カラーピッカー
                PopupMenuButton<Color>(
                  onSelected: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  itemBuilder: (context) => [
                    Colors.red[600]!,
                    Colors.pink[600]!,
                    Colors.purple[600]!,
                    Colors.deepPurple[600]!,
                    Colors.indigo[600]!,
                    Colors.blue[600]!,
                    Colors.lightBlue[600]!,
                    Colors.cyan[600]!,
                    Colors.teal[600]!,
                    Colors.green[600]!,
                    Colors.lightGreen[600]!,
                    Colors.lime[600]!,
                    Colors.yellow[600]!,
                    Colors.amber[600]!,
                    Colors.orange[600]!,
                    Colors.deepOrange[600]!,
                    Colors.brown[600]!,
                    Colors.grey[600]!,
                  ].map((color) => PopupMenuItem(
                    value: color,
                    child: Container(
                      width: 100,
                      height: 30,
                      color: color,
                    ),
                  )).toList(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_customTagController.text.isNotEmpty) {
                      tagService.addCustomTag(
                        _customTagController.text,
                        _selectedColor,
                      );
                      tagService.addTag(widget.userId, _customTagController.text);
                      _customTagController.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}