import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/smart_customers_page.dart';
import '../../features/customers/presentation/pages/customers_split_page.dart';
import '../../features/customers/presentation/pages/enhanced_customers_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_conversation_page.dart';
import '../../features/chat/presentation/pages/qr_code_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/staff/presentation/pages/staff_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/layouts/admin_layout.dart';
import '../services/auth_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final _authService = AuthService();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/chat', // チャットページをスタートページに
    redirect: (context, state) {
      // 開発中は認証をスキップ
      return null;
      
      // 本番環境では以下のコメントを外す
      // final isAuthenticated = _authService.isAuthenticated;
      // final isLoginPage = state.matchedLocation == '/login';
      // 
      // if (!isAuthenticated && !isLoginPage) {
      //   return '/login';
      // }
      // 
      // if (isAuthenticated && isLoginPage) {
      //   return '/dashboard';
      // }
      // 
      // return null;
    },
    refreshListenable: _authService,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ChatListPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
            routes: [
              GoRoute(
                path: 'conversation/:chatId',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: ChatConversationPage(
                    chatId: state.pathParameters['chatId'] ?? '',
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: 'qr',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const QRCodePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const EnhancedCustomersPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AppointmentsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/services',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ServicesPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/staff',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StaffPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AnalyticsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/settings/theme',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ThemeSettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    ],
  );
}