import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// iOS SafeArea対応のためのヘルパークラス
class IOSSafeAreaHelper {
  /// iOSプラットフォームかどうかを判定
  static bool get isIOS {
    try {
      return Platform.isIOS;
    } catch (e) {
      // Web環境など、Platformが使えない場合はfalseを返す
      return false;
    }
  }

  /// SafeAreaを適用したウィジェットを返す
  /// iOSの場合のみSafeAreaを適用し、他のプラットフォームではそのまま返す
  static Widget wrapWithSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    if (isIOS) {
      return SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      );
    }
    return child;
  }

  /// iOSのステータスバーの高さを考慮したパディングを返す
  static EdgeInsets getIOSPadding(BuildContext context) {
    if (isIOS) {
      final padding = MediaQuery.of(context).padding;
      return EdgeInsets.only(
        top: padding.top > 0 ? padding.top : 20, // 最小20pxのパディング
      );
    }
    return EdgeInsets.zero;
  }

  /// iOSのボトムセーフエリア（ホームインジケーター）の高さを考慮したパディングを返す
  static EdgeInsets getIOSBottomPadding(BuildContext context) {
    if (isIOS) {
      final padding = MediaQuery.of(context).padding;
      return EdgeInsets.only(
        bottom: padding.bottom > 0 ? padding.bottom : 0,
      );
    }
    return EdgeInsets.zero;
  }
}