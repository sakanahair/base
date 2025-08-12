import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/simplified_auth_service.dart';
import '../../core/services/multi_tenant_service.dart';

class SuperAdminMenu extends StatelessWidget {
  const SuperAdminMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SimplifiedAuthService>(context);
    final multiTenantService = Provider.of<MultiTenantService>(context);
    
    if (!authService.isAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'SUPER管理者メニュー',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (multiTenantService.currentSite != null)
                Chip(
                  label: Text(
                    '現在のサイト: ${multiTenantService.currentSite!.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                context,
                icon: Icons.person_add,
                label: 'ユーザー作成',
                onTap: () => _navigateToUserCreation(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.business,
                label: 'サイト管理',
                onTap: () => _navigateToSiteManagement(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.group,
                label: 'ユーザー管理',
                onTap: () => _navigateToUserManagement(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.assignment,
                label: 'サイト割り当て',
                onTap: () => _navigateToSiteAssignment(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.analytics,
                label: '利用統計',
                onTap: () => _navigateToStatistics(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.settings_applications,
                label: 'システム設定',
                onTap: () => _navigateToSystemSettings(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserCreation(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/create-user');
  }

  void _navigateToSiteManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/sites');
  }

  void _navigateToUserManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/users');
  }

  void _navigateToSiteAssignment(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/site-assignment');
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/statistics');
  }

  void _navigateToSystemSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/super-admin/settings');
  }
}