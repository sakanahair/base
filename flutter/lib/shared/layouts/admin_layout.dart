import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../features/terminal/presentation/pages/terminal_page.dart';
import '../../features/terminal/presentation/pages/multi_terminal_page.dart';
import '../utils/responsive_helper.dart';

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
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'チャット',
      route: '/chat',
    ),
    _MenuItem(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
      label: 'SAKANA AI',
      route: '/ai-chat',
      customIcon: 'assets/images/sakana_logo.png',
    ),
    _MenuItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: '顧客管理',
      route: '/customers',
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
    // モバイルではヘッダーを小さくするか、非表示にする
    if (isMobile) {
      return Container(
        height: 48, // モバイルでは小さなヘッダー
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
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
            style: const TextStyle(
              color: Colors.white,
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
        color: AppTheme.primaryColor,
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
              icon: const Icon(Icons.menu, color: Colors.white),
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
                color: Colors.white,
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
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                baseFontSize: 18,
                mobileScale: 0.9,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Terminal Button (開発環境のみ)
          if (kDebugMode)
            IconButton(
              iconSize: context.responsiveIconSize,
              icon: const Icon(Icons.terminal, color: Colors.white),
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
          
          // Notification Button
          if (!isMobile || isTablet)
            Stack(
              children: [
                IconButton(
                  iconSize: context.responsiveIconSize,
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
          
          // Profile Menu
          Padding(
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.secondaryColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '管理者',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
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
                if (value == 'logout') {
                  _authService.logout();
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigation(BuildContext context) {
    // Only show main navigation items on bottom nav (first 5)
    final mainItems = _menuItems.take(5).toList();
    
    return Container(
      height: 56, // 固定の高さに設定
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 22,
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
          icon: item.customIcon != null
              ? Image.network(
                  '/admin/logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.catching_pokemon,
                      size: 24,
                    );
                  },
                )
              : Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 24,
                ),
          label: _getShortLabel(item.label),
        );
      }).toList(),
      ),
    );
  }
  
  Widget _buildMobileFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        ResponsiveHelper.addHapticFeedbackMedium();
        _showQuickActions(context);
      },
      backgroundColor: AppTheme.secondaryColor,
      child: const Icon(
        Icons.add,
        color: Colors.white,
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
                    color: isActive ? AppTheme.activeBackgroundColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border(
                            left: BorderSide(
                              color: AppTheme.secondaryColor,
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
                        context.go(item.route);
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
                                            ? AppTheme.secondaryColor
                                            : AppTheme.textSecondary,
                                      );
                                    },
                                  )
                                : Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: context.responsiveIconSize,
                                    color: isActive
                                        ? AppTheme.secondaryColor
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
                                        ? AppTheme.secondaryColor
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