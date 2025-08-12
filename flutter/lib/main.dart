import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/customer_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/tag_service.dart';
import 'core/config/firebase_config.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable overflow errors in release mode
  if (kReleaseMode) {
    debugPaintSizeEnabled = false;
  }
  
  // Optionally disable overflow indicators even in debug mode
  // Remove the comment below to completely disable overflow errors
  debugDisableClipLayers = true;
  
  // Set URL strategy for web
  setUrlStrategy(PathUrlStrategy());
  
  // Initialize Firebase (optional for mock data)
  // await FirebaseConfig.initialize();
  
  // Initialize date formatting for Japanese
  await initializeDateFormatting('ja_JP', null);
  
  // メインアプリを起動
  runApp(const SakanaAdminApp());
}

class SimpleDashboardApp extends StatelessWidget {
  const SimpleDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAKANA Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SimpleDashboard(),
    );
  }
}

class SimpleDashboard extends StatelessWidget {
  const SimpleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAKANA Dashboard'),
        backgroundColor: Colors.blue,
        toolbarHeight: isMobile ? 48 : 56,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ダッシュボード',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildCard('売上', '¥125,000', Colors.green, Icons.attach_money),
                _buildCard('顧客数', '342', Colors.blue, Icons.people),
                _buildCard('予約', '28', Colors.orange, Icons.calendar_today),
                _buildCard('メッセージ', '15', Colors.purple, Icons.message),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ダッシュボード'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '顧客'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ) : null,
    );
  }
  
  Widget _buildCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          title: const Text('モバイルテスト'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '動作確認',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) => Text(
                  'Width: ${MediaQuery.of(context).size.width}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('テストボタン'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
          ],
        ),
      ),
    );
  }
}

class MinimalTestApp extends StatelessWidget {
  const MinimalTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Container(
          color: Colors.blue,
          child: const Center(
            child: Text(
              'TEST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
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