import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/enhanced_auth_service.dart';
import '../../core/services/multi_tenant_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/site_model.dart';

class SiteAssignmentScreen extends StatefulWidget {
  const SiteAssignmentScreen({super.key});

  @override
  State<SiteAssignmentScreen> createState() => _SiteAssignmentScreenState();
}

class _SiteAssignmentScreenState extends State<SiteAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _allUsers = [];
  List<SiteModel> _allSites = [];
  Map<String, List<UserModel>> _siteUsersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final multiTenantService = Provider.of<MultiTenantService>(
        context,
        listen: false,
      );

      _allSites = multiTenantService.managedSites;

      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _allUsers = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      _siteUsersMap = {};
      for (final site in _allSites) {
        _siteUsersMap[site.id] = _allUsers
            .where((user) => user.siteId == site.id)
            .toList();
      }

      final unassignedUsers = _allUsers
          .where((user) => user.siteId == null && user.role != UserRole.superAdmin)
          .toList();
      
      if (unassignedUsers.isNotEmpty) {
        _siteUsersMap['unassigned'] = unassignedUsers;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<EnhancedAuthService>(context);
    
    if (!authService.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('アクセス拒否')),
        body: const Center(
          child: Text('このページへのアクセス権限がありません'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('サイト割り当て管理'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildSitesList(),
                ),
                Expanded(
                  flex: 2,
                  child: _buildAssignmentView(),
                ),
              ],
            ),
    );
  }

  Widget _buildSitesList() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade700,
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'サイト一覧',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_siteUsersMap.containsKey('unassigned'))
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('未割り当て'),
              subtitle: Text('${_siteUsersMap['unassigned']!.length}名'),
              tileColor: Colors.orange.shade50,
              onTap: () {
                setState(() {});
              },
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _allSites.length,
              itemBuilder: (context, index) {
                final site = _allSites[index];
                final userCount = _siteUsersMap[site.id]?.length ?? 0;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        Text('ユーザー数: $userCount'),
                        if (site.userLimit != null)
                          LinearProgressIndicator(
                            value: userCount / site.userLimit!,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              userCount >= site.userLimit!
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.deepPurple.shade700),
                  const SizedBox(width: 12),
                  Text(
                    'ユーザー割り当て状況',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('総ユーザー数: ${_allUsers.length}'),
                    backgroundColor: Colors.deepPurple.shade100,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                if (_siteUsersMap.containsKey('unassigned'))
                  _buildUserSection(
                    '未割り当てユーザー',
                    _siteUsersMap['unassigned']!,
                    Colors.orange,
                    null,
                  ),
                ..._allSites.map((site) {
                  final users = _siteUsersMap[site.id] ?? [];
                  return _buildUserSection(
                    site.name,
                    users,
                    _getStatusColor(site.status),
                    site,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(
    String title,
    List<UserModel> users,
    Color color,
    SiteModel? site,
  ) {
    if (users.isEmpty && site != null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            users.length.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(title),
        subtitle: site != null
            ? Text('${site.domain} | ${_getStatusText(site.status)}')
            : null,
        children: users.map((user) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.name),
            subtitle: Text('${user.email} | ${_getRoleDisplayName(user.role)}'),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'reassign') {
                  _showReassignDialog(user);
                } else if (value == 'remove') {
                  _removeFromSite(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reassign',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('サイト変更'),
                    ],
                  ),
                ),
                if (user.siteId != null)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('サイトから削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReassignDialog(UserModel user) {
    SiteModel? selectedSite;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name}のサイト変更'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在のサイト: ${user.siteId ?? "未割り当て"}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<SiteModel>(
                value: selectedSite,
                decoration: const InputDecoration(
                  labelText: '新しいサイト',
                  border: OutlineInputBorder(),
                ),
                items: _allSites.map((site) {
                  return DropdownMenuItem(
                    value: site,
                    child: Text(site.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSite = value;
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
            onPressed: selectedSite == null
                ? null
                : () async {
                    await _reassignUser(user, selectedSite!);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }

  Future<void> _reassignUser(UserModel user, SiteModel newSite) async {
    try {
      if (user.siteId != null) {
        await _firestore.collection('sites').doc(user.siteId).update({
          'currentUserCount': FieldValue.increment(-1),
        });
      }

      await _firestore.collection('users').doc(user.id).update({
        'siteId': newSite.id,
      });

      await _firestore.collection('sites').doc(newSite.id).update({
        'currentUserCount': FieldValue.increment(1),
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name}を${newSite.name}に割り当てました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromSite(UserModel user) async {
    if (user.siteId == null) return;

    try {
      await _firestore.collection('sites').doc(user.siteId).update({
        'currentUserCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(user.id).update({
        'siteId': FieldValue.delete(),
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザーをサイトから削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.deepPurple;
      case UserRole.siteAdmin:
        return Colors.blue;
      case UserRole.endUser:
        return Colors.teal;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'スーパー管理者';
      case UserRole.siteAdmin:
        return 'サイト管理者';
      case UserRole.endUser:
        return 'エンドユーザー';
    }
  }
}