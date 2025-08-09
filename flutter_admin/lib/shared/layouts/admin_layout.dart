import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isSidebarCollapsed = false;
  bool _isMobileSidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768;
    final currentRoute = GoRouterState.of(context).uri.path;

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
                Container(
                  height: 64,
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
                      // Mobile Menu Button
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isMobileSidebarOpen = !_isMobileSidebarOpen;
                            });
                          },
                        ),
                      
                      // Desktop Collapse Button
                      if (isDesktop)
                        IconButton(
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
                      
                      const SizedBox(width: 16),
                      
                      // Title
                      Text(
                        'Sakana Hair Admin',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Notification Button
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: () {},
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PopupMenuButton<String>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
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
                            if (value == 'logout') {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Page Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Mobile Drawer
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: AppTheme.sidebarBackgroundColor,
              child: _buildSidebar(currentRoute, false),
            )
          : null,
    );
  }

  Widget _buildSidebar(String currentRoute, bool isDesktop) {
    final menuItems = [
      _MenuItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'ダッシュボード',
        route: '/dashboard',
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

    return Container(
      color: AppTheme.sidebarBackgroundColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 64,
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
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'S',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sakana Hair',
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
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
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
                        context.go(item.route);
                        if (!isDesktop) {
                          Navigator.pop(context);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarCollapsed ? 20 : 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 20,
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

  _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}