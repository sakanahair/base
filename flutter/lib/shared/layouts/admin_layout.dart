import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/simplified_auth_service.dart';
import '../../core/services/theme_service.dart';
import 'package:provider/provider.dart';
import '../../features/terminal/presentation/pages/terminal_page.dart';
import '../../features/terminal/presentation/pages/multi_terminal_page.dart';
import '../utils/responsive_helper.dart';
import '../widgets/smart_memo_pad.dart';
import '../../core/services/memo_service.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  final _authService = AuthService();
  int _currentBottomNavIndex = 0;
  
  final List<_MenuItem> _menuItems = [
    _MenuItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'ダッシュボード',
      route: '/dashboard',
    ),
    _MenuItem(
      icon: Icons.catching_pokemon,
      activeIcon: Icons.catching_pokemon,
      label: 'チャット',
      route: '/chat',
      customIcon: 'assets/images/sakana_logo.png',
    ),
    _MenuItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: '予約管理',
      route: '/appointments',
    ),
    _MenuItem(
      icon: Icons.cut_outlined,
      activeIcon: Icons.cut,
      label: 'サービス管理',
      route: '/services',
    ),
    _MenuItem(
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge,
      label: 'スタッフ管理',
      route: '/staff',
    ),
    _MenuItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: '分析',
      route: '/analytics',
    ),
    _MenuItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '設定',
      route: '/settings',
    ),
    _MenuItem(
      icon: Icons.logout_outlined,
      activeIcon: Icons.logout,
      label: 'ログアウト',
      route: '/logout',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBottomNavIndex();
  }
  
  @override
  void didUpdateWidget(AdminLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateBottomNavIndex();
  }
  
  void _updateBottomNavIndex() {
    final currentRoute = GoRouterState.of(context).uri.path;
    final index = _menuItems.indexWhere((item) => item.route == currentRoute);
    if (index != -1 && index != _currentBottomNavIndex) {
      setState(() {
        _currentBottomNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final themeService = context.watch<ThemeService>();
    
    // iOSのステータスバーの色を設定
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: themeService.isDarkMode ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: themeService.onPrimaryColor == Colors.white 
            ? Brightness.light 
            : Brightness.dark,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isSidebarCollapsed ? 80 : 256,
              child: _buildSidebar(currentRoute, isDesktop),
            ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                _buildHeader(context, currentRoute, isMobile, isTablet, isDesktop),
                
                // Page Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Mobile Drawer (kept for swipe gesture)
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: AppTheme.sidebarBackgroundColor,
              width: ResponsiveHelper.getDrawerWidth(context),
              child: _buildSidebar(currentRoute, false),
            )
          : null,
      
      // Mobile Bottom Navigation
      bottomNavigationBar: isMobile
          ? _buildBottomNavigation(context)
          : null,
      
      // Floating Action Button for mobile
      floatingActionButton: isMobile
          ? _buildMobileFAB(context)
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, String currentRoute, bool isMobile, bool isTablet, bool isDesktop) {
    final themeService = Provider.of<ThemeService>(context);
    // モバイルではヘッダーを小さくするか、非表示にする
    if (isMobile) {
      return Container(
        height: 48, // モバイルでは小さなヘッダー
        decoration: BoxDecoration(
          color: themeService.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'SAKANA Platform',
            style: TextStyle(
              color: themeService.onPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: ResponsiveHelper.getAppBarHeight(context),
      decoration: BoxDecoration(
        color: themeService.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mobile Menu Button - REMOVED for mobile
          // Only show for tablet
          if (isTablet)
            IconButton(
              iconSize: context.responsiveIconSize,
              icon: Icon(Icons.menu, color: themeService.onPrimaryColor),
              onPressed: () {
                ResponsiveHelper.addHapticFeedback();
                Scaffold.of(context).openDrawer();
              },
            ),
          
          // Desktop Collapse Button
          if (isDesktop)
            IconButton(
              iconSize: context.responsiveIconSize,
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                color: themeService.onPrimaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          
          SizedBox(width: isMobile ? 8 : 16),
          
          // Title
          Text(
            isMobile ? 'SAKANA' : 'SAKANA Admin',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: themeService.onPrimaryColor,
              fontWeight: FontWeight.w300,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Terminal Button (開発環境のみ)
          if (kDebugMode)
            IconButton(
              iconSize: context.responsiveIconSize,
              icon: Icon(Icons.terminal, color: themeService.onPrimaryColor),
              onPressed: () {
                if (context.isTouchDevice) {
                  ResponsiveHelper.addHapticFeedback();
                }
                // ターミナルをモーダルで表示
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const MultiTerminalPage(),
                      ),
                    ),
                  ),
                );
              },
              tooltip: 'Terminal',
            ),
          
          // Memo Button
          if (!isMobile || isTablet)
            IconButton(
              iconSize: context.responsiveIconSize,
              icon: Icon(Icons.note_alt_outlined, color: themeService.onPrimaryColor),
              onPressed: () {
                if (context.isTouchDevice) {
                  ResponsiveHelper.addHapticFeedback();
                }
                // メモ帳を開く
                showDialog(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.8,
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                        maxHeight: 600,
                      ),
                      child: Consumer<MemoService>(
                        builder: (context, memoService, child) {
                          final generalMemo = memoService.getGeneralMemo();
                          return SmartMemoPad(
                            isDialog: true,
                            initialText: generalMemo.isNotEmpty ? generalMemo : null,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              tooltip: 'メモ帳',
            ),
          
          // Notification Button
          if (!isMobile || isTablet)
            Stack(
              children: [
                IconButton(
                  iconSize: context.responsiveIconSize,
                  icon: Icon(Icons.notifications_outlined, color: themeService.onPrimaryColor),
                  onPressed: () {
                    if (context.isTouchDevice) {
                      ResponsiveHelper.addHapticFeedback();
                    }
                    // TODO: Show notifications
                  },
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          
          // Profile Menu with Crown Badge for Super Admin
          Consumer<SimplifiedAuthService>(
            builder: (context, authService, child) {
              final isSuperAdmin = authService.isAdmin;
              
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                ),
                child: PopupMenuButton<String>(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSuperAdmin ? Colors.amber : AppTheme.secondaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 20,
                                color: isSuperAdmin ? Colors.amber : AppTheme.secondaryColor,
                              ),
                            ),
                            if (isSuperAdmin)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          Text(
                            isSuperAdmin ? 'SUPER管理者' : '管理者',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: themeService.onPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: themeService.onPrimaryColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 12),
                          Text('プロフィール'),
                        ],
                      ),
                    ),
                    if (isSuperAdmin) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'create_user',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, size: 20, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('ユーザー作成'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'manage_sites',
                        child: Row(
                          children: [
                            Icon(Icons.business, size: 20, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('サイト管理'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'manage_users',
                        child: Row(
                          children: [
                            Icon(Icons.group, size: 20, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('ユーザー管理'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'site_assignment',
                        child: Row(
                          children: [
                            Icon(Icons.assignment, size: 20, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('サイト割り当て'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('ログアウト'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (context.isTouchDevice) {
                      ResponsiveHelper.addHapticFeedback();
                    }
                    switch (value) {
                      case 'logout':
                        _authService.logout();
                        context.go('/login');
                        break;
                      case 'create_user':
                        context.go('/super-admin/create-user');
                        break;
                      case 'manage_sites':
                        context.go('/super-admin/sites');
                        break;
                      case 'manage_users':
                        context.go('/super-admin/users');
                        break;
                      case 'site_assignment':
                        context.go('/super-admin/site-assignment');
                        break;
                      case 'profile':
                        // TODO: Navigate to profile
                        break;
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigation(BuildContext context) {
    // Only show main navigation items on bottom nav (first 5)
    final mainItems = _menuItems.take(5).toList();
    
    return Theme(
      data: Theme.of(context).copyWith(
        // BottomNavigationBarの高さとパディングを調整
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        iconSize: 20,
        elevation: 8,
        // アイテムの高さを調整
        selectedLabelStyle: const TextStyle(height: 1.0),
        unselectedLabelStyle: const TextStyle(height: 1.0),
        currentIndex: _currentBottomNavIndex.clamp(0, mainItems.length - 1),
        onTap: (index) {
          ResponsiveHelper.addHapticFeedback();
          final item = mainItems[index];
          context.go(item.route);
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
        items: mainItems.map((item) {
          final isActive = _menuItems.indexOf(item) == _currentBottomNavIndex;
          return BottomNavigationBarItem(
            icon: Container(
              height: 20,
              width: 20,
              child: item.customIcon != null
                  ? Image.network(
                      '/admin/logo.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.catching_pokemon,
                          size: 20,
                        );
                      },
                    )
                  : Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 20,
                    ),
            ),
            label: _getShortLabel(item.label),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildMobileFAB(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return FloatingActionButton(
      onPressed: () {
        ResponsiveHelper.addHapticFeedbackMedium();
        _showQuickActions(context);
      },
      backgroundColor: themeService.primaryColor,
      child: Icon(
        Icons.add,
        color: themeService.onPrimaryColor,
      ),
    );
  }
  
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'クイックアクション',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.add,
                  label: '新規予約',
                  color: AppTheme.infoColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/appointments');
                  },
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.person_add,
                  label: '顧客登録',
                  color: AppTheme.successColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/customers');
                  },
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.analytics,
                  label: '分析',
                  color: AppTheme.warningColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/analytics');
                  },
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.settings,
                  label: '設定',
                  color: AppTheme.errorColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ResponsiveHelper.addHapticFeedback();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getShortLabel(String label) {
    switch (label) {
      case 'ダッシュボード':
        return 'ホーム';
      case '顧客管理':
        return '顧客';
      case '予約管理':
        return '予約';
      case 'サービス管理':
        return 'サービス';
      case 'スタッフ管理':
        return 'スタッフ';
      default:
        return label;
    }
  }
  
  Widget _buildSidebar(String currentRoute, bool isDesktop) {
    final themeService = Provider.of<ThemeService>(context);

    return Container(
      color: AppTheme.sidebarBackgroundColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: ResponsiveHelper.getAppBarHeight(context),
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 16 : 24,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.5),
                ),
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSidebarCollapsed
                    ? Image.network(
                        '/admin/logo.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.catching_pokemon,
                            size: 40,
                            color: AppTheme.secondaryColor,
                          );
                        },
                      )
                    : Row(
                        children: [
                          Image.network(
                            '/admin/logo.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.catching_pokemon,
                                size: 40,
                                color: AppTheme.secondaryColor,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAKANA Hair',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '管理システム',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 200.ms),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isActive = currentRoute == item.route;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? themeService.primaryColorBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border(
                            left: BorderSide(
                              color: themeService.primaryColor,
                              width: 4,
                            ),
                          )
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (context.isTouchDevice) {
                          ResponsiveHelper.addHapticFeedback();
                        }
                        
                        // Handle logout specially
                        if (item.route == '/logout') {
                          _authService.logout();
                          context.go('/login');
                        } else {
                          context.go(item.route);
                        }
                        
                        if (!isDesktop) {
                          Navigator.pop(context);
                        }
                        setState(() {
                          _currentBottomNavIndex = index;
                        });
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: ResponsiveHelper.minTouchTarget,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarCollapsed ? 20 : 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            item.customIcon != null
                                ? Image.network(
                                    '/admin/logo.png',
                                    width: context.responsiveIconSize,
                                    height: context.responsiveIconSize,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.catching_pokemon,
                                        size: context.responsiveIconSize,
                                        color: isActive
                                            ? themeService.primaryColor
                                            : AppTheme.textSecondary,
                                      );
                                    },
                                  )
                                : Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: context.responsiveIconSize,
                                    color: isActive
                                        ? themeService.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                            if (!_isSidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                                    color: isActive
                                        ? themeService.primaryColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
          
          // Bottom Section
          Container(
            padding: EdgeInsets.all(_isSidebarCollapsed ? 16 : 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.5),
                ),
              ),
            ),
            child: _isSidebarCollapsed
                ? const Icon(
                    Icons.help_outline,
                    size: 24,
                    color: AppTheme.textTertiary,
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.help_outline,
                        size: 20,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ヘルプ＆サポート',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String? customIcon;

  _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.customIcon,
  });
}