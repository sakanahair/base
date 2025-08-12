import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/multi_tenant_service.dart';
import '../../core/models/site_model.dart';

class SiteManagementScreen extends StatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  State<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends State<SiteManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final multiTenantService = Provider.of<MultiTenantService>(context);
    
    if (!multiTenantService.isSuperAdmin) {
      return const Center(
        child: Text('このページへのアクセス権限がありません'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('サイト管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSiteDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '登録サイト一覧',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: multiTenantService.managedSites.length,
                itemBuilder: (context, index) {
                  final site = multiTenantService.managedSites[index];
                  return _buildSiteCard(site, multiTenantService);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteCard(SiteModel site, MultiTenantService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(site.status),
          child: Text(
            site.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(site.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ドメイン: ${site.domain}'),
            Text('ステータス: ${_getStatusText(site.status)}'),
            if (site.currentUserCount != null)
              Text('ユーザー数: ${site.currentUserCount}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (service.currentSite?.id == site.id)
              const Chip(
                label: Text('現在選択中'),
                backgroundColor: Colors.green,
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSiteSettingsDialog(context, site),
            ),
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () async {
                await service.switchSite(site.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${site.name}に切り替えました'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SiteStatus status) {
    switch (status) {
      case SiteStatus.active:
        return Colors.green;
      case SiteStatus.trial:
        return Colors.orange;
      case SiteStatus.suspended:
        return Colors.red;
      case SiteStatus.inactive:
        return Colors.grey;
    }
  }

  String _getStatusText(SiteStatus status) {
    switch (status) {
      case SiteStatus.active:
        return 'アクティブ';
      case SiteStatus.trial:
        return 'トライアル';
      case SiteStatus.suspended:
        return '停止中';
      case SiteStatus.inactive:
        return '非アクティブ';
    }
  }

  void _showCreateSiteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final domainController = TextEditingController();
    final subdomainController = TextEditingController();
    final ownerEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規サイト作成'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'サイト名',
                  hintText: '例: SAKANA HAIR 渋谷店',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: domainController,
                decoration: const InputDecoration(
                  labelText: 'ドメイン',
                  hintText: '例: sakana-shibuya.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subdomainController,
                decoration: const InputDecoration(
                  labelText: 'サブドメイン（オプション）',
                  hintText: '例: shibuya',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerEmailController,
                decoration: const InputDecoration(
                  labelText: 'オーナーメールアドレス',
                  hintText: '例: owner@sakana-shibuya.com',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = Provider.of<MultiTenantService>(
                context,
                listen: false,
              );
              
              final site = await service.createSite(
                name: nameController.text,
                domain: domainController.text,
                subdomain: subdomainController.text.isEmpty
                    ? null
                    : subdomainController.text,
                ownerId: ownerEmailController.text,
              );

              if (mounted) {
                Navigator.of(context).pop();
                if (site != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('サイトを作成しました'),
                    ),
                  );
                }
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _showSiteSettingsDialog(BuildContext context, SiteModel site) {
    final maxUsersController = TextEditingController(
      text: site.settings['maxUsers']?.toString() ?? '100',
    );
    bool allowRegistration = site.settings['allowRegistration'] ?? true;
    bool requireEmailVerification = 
        site.settings['requireEmailVerification'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${site.name} の設定'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: maxUsersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '最大ユーザー数',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('新規登録を許可'),
                  value: allowRegistration,
                  onChanged: (value) {
                    setState(() {
                      allowRegistration = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('メール認証を必須にする'),
                  value: requireEmailVerification,
                  onChanged: (value) {
                    setState(() {
                      requireEmailVerification = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final service = Provider.of<MultiTenantService>(
                  context,
                  listen: false,
                );
                
                await service.updateSiteSettings(site.id, {
                  'maxUsers': int.tryParse(maxUsersController.text) ?? 100,
                  'allowRegistration': allowRegistration,
                  'requireEmailVerification': requireEmailVerification,
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('設定を更新しました'),
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}