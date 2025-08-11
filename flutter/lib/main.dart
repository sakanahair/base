import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/customer_service.dart';
import 'core/services/theme_service.dart';
import 'core/config/firebase_config.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set URL strategy for web
  setUrlStrategy(PathUrlStrategy());
  
  // Initialize Firebase (optional for mock data)
  // await FirebaseConfig.initialize();
  
  // Initialize date formatting for Japanese
  await initializeDateFormatting('ja_JP', null);
  
  runApp(const SakanaAdminApp());
}

class SakanaAdminApp extends StatefulWidget {
  const SakanaAdminApp({super.key});

  @override
  State<SakanaAdminApp> createState() => _SakanaAdminAppState();
}

class _SakanaAdminAppState extends State<SakanaAdminApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'SAKANA Platform',
            theme: themeService.generateThemeData(),
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}