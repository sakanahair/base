import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set URL strategy for web
  setUrlStrategy(PathUrlStrategy());
  
  // Initialize date formatting for Japanese
  await initializeDateFormatting('ja_JP', null);
  
  runApp(const SakanaAdminApp());
}

class SakanaAdminApp extends StatelessWidget {
  const SakanaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sakana Hair Admin',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}