import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/customer_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/tag_service.dart';
import 'core/services/auth_service.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable overflow errors in release mode
  if (kReleaseMode) {
    debugPaintSizeEnabled = false;
  }
  
  // Optionally disable overflow indicators even in debug mode
  debugDisableClipLayers = true;
  
  // Set URL strategy for web
  setUrlStrategy(PathUrlStrategy());
  
  try {
    // Initialize Firebase with FlutterFire generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase if initialization fails
  }
  
  // Initialize date formatting for Japanese
  await initializeDateFormatting('ja_JP', null);
  
  // メインアプリを起動
  runApp(const SakanaAdminApp());
}

class SakanaAdminApp extends StatefulWidget {
  const SakanaAdminApp({super.key});

  @override
  State<SakanaAdminApp> createState() => _SakanaAdminAppState();
}

class _SakanaAdminAppState extends State<SakanaAdminApp> {
  @override
  void initState() {
    super.initState();
    // Disable overflow error display
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In release mode, show nothing
      if (kReleaseMode) {
        return Container();
      }
      // In debug mode, show a simple red container instead of the yellow-black stripes
      return Container(
        color: Colors.red.withOpacity(0.1),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => TagService()),
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