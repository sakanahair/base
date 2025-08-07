import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'マルチプラットフォーム Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  String getPlatformName() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    }
    return 'Unknown';
  }

  Widget _buildPlatformInfo() {
    final platform = getPlatformName();
    final isWeb = kIsWeb;
    final isMobile = !isWeb && (Platform.isIOS || Platform.isAndroid);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プラットフォーム情報',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('現在のプラットフォーム', platform),
            _buildInfoRow('Web環境', isWeb ? 'はい' : 'いいえ'),
            _buildInfoRow('モバイル環境', isMobile ? 'はい' : 'いいえ'),
            _buildInfoRow('画面幅', '${MediaQuery.of(context).size.width.toStringAsFixed(0)}px'),
            _buildInfoRow('画面高さ', '${MediaQuery.of(context).size.height.toStringAsFixed(0)}px'),
            _buildInfoRow('デバイスピクセル比', MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.phone_iphone, 'title': 'レスポンシブデザイン', 'description': '画面サイズに応じて自動調整'},
      {'icon': Icons.palette, 'title': 'マテリアルデザイン3', 'description': '最新のUIコンポーネント'},
      {'icon': Icons.speed, 'title': '高速パフォーマンス', 'description': 'ネイティブレベルの実行速度'},
      {'icon': Icons.code, 'title': 'ホットリロード', 'description': '開発中の即座の変更反映'},
      {'icon': Icons.devices, 'title': 'クロスプラットフォーム', 'description': '1つのコードベースで複数OS対応'},
      {'icon': Icons.widgets, 'title': '豊富なウィジェット', 'description': 'カスタマイズ可能なUIコンポーネント'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              feature['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            title: Text(
              feature['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(feature['description'] as String),
          ),
        );
      },
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '設定',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('通知を有効にする'),
          subtitle: const Text('アプリからの通知を受け取る'),
          value: true,
          onChanged: (value) {},
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('言語'),
          subtitle: const Text('日本語'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('テーマ'),
          subtitle: const Text('システム設定に従う'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('バージョン'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('プライバシーポリシー'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;
    
    final List<Widget> pages = [
      _buildPlatformInfo(),
      _buildFeatureList(),
      _buildSettings(),
    ];

    if (kIsWeb || isWideScreen) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Flutter マルチプラットフォーム App'),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('ホーム'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: Text('機能'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('設定'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: pages[_selectedIndex],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Flutter App'),
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: '機能',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '設定',
            ),
          ],
        ),
      );
    }
  }
}