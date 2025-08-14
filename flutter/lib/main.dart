import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// Web専用のインポートを条件付きに
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/customer_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/tag_service.dart';
import 'core/services/memo_service.dart';
import 'core/services/image_service.dart';
import 'core/services/service_service.dart';
import 'core/services/simplified_auth_service.dart';
import 'core/services/enhanced_auth_service.dart';
import 'core/services/multi_tenant_service.dart';
import 'core/utils/setup_super_admin.dart';
import 'shared/widgets/splash_screen.dart';

// Web専用のインポートとスタブを条件付きで
import 'web_url_strategy_stub.dart'
  if (dart.library.html) 'web_url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable overflow errors in release mode
  if (kReleaseMode) {
    debugPaintSizeEnabled = false;
  }
  
  // Optionally disable overflow indicators even in debug mode
  debugDisableClipLayers = true;
  
  // Set URL strategy for web only
  if (kIsWeb) {
    setUrlStrategy();
  }
  
  // Initialize Firebase for all platforms
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // スーパー管理者の初期セットアップ（開発時のみ）
    // 本番環境では削除またはコメントアウトしてください
    if (!kReleaseMode && kIsWeb) {
      await setupSuperAdmin(); // 初回実行後はコメントアウト推奨
    }
  } catch (e) {
    print('Firebase initialization error: $e');
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
        ChangeNotifierProvider(create: (_) => SimplifiedAuthService()),
        ChangeNotifierProvider(create: (_) => EnhancedAuthService()),
        ChangeNotifierProvider(create: (_) => MultiTenantService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => TagService()),
        ChangeNotifierProvider(create: (_) => MemoService()),
        ChangeNotifierProvider(create: (_) => ImageService()),
        ChangeNotifierProxyProvider<SimplifiedAuthService, ServiceService>(
          create: (context) => ServiceService(context.read<SimplifiedAuthService>()),
          update: (context, auth, previous) => previous ?? ServiceService(auth),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // iOSのステータスバーの色を設定
          if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS) {
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: themeService.primaryColor,
                statusBarBrightness: themeService.isDarkMode ? Brightness.dark : Brightness.light,
                statusBarIconBrightness: themeService.onPrimaryColor == Colors.white 
                  ? Brightness.light 
                  : Brightness.dark,
              ),
            );
          }
          
          return MaterialApp.router(
            title: 'SAKANA Platform',
            theme: themeService.generateThemeData(),
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            // プラットフォーム間でデザインを統一
            themeMode: ThemeMode.light,
            // iOSでもMaterial Designを使用
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior(),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}