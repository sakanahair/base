import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/theme_service.dart';

class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;

  const UnifiedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.leadingWidth,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    // テーマサービスからフォントサイズを取得
    double titleFontSize = 18.0; // デフォルトサイズ
    switch (themeService.fontSize) {
      case 'xs':
        titleFontSize = 14.0;
        break;
      case 's':
        titleFontSize = 16.0;
        break;
      case 'm':
        titleFontSize = 18.0;
        break;
      case 'l':
        titleFontSize = 20.0;
        break;
      case 'xl':
        titleFontSize = 22.0;
        break;
    }

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          fontFamily: themeService.fontFamily,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leadingWidth: leadingWidth,
      leading: automaticallyImplyLeading && Navigator.canPop(context)
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: titleFontSize * 1.2, // タイトルサイズに比例
                color: Colors.black87,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}