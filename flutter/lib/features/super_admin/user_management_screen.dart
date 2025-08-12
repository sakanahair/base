import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/services/enhanced_auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/site_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  Map<String, SiteModel> _sitesMap = {};
  bool _isLoading = true;
  
  String _searchQuery = '';
  UserRole? _filterRole;
  String? _filterSiteId;

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
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      final sitesSnapshot = await _firestore.collection('sites').get();
      _sitesMap = {
        for (var doc in sitesSnapshot.docs)
          doc.id: SiteModel.fromFirestore(doc)
      };

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.name.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_filterRole != null && user.role != _filterRole) {
        return false;
      }

      if (_filterSiteId != null && user.siteId != _filterSiteId) {
        return false;
      }

      return true;
    }).toList();
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
        title: const Text('ユーザー管理'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/super-admin/create-user')
                  .then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatistics(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: '名前またはメールで検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<UserRole?>(
              value: _filterRole,
              decoration: InputDecoration(
                labelText: 'ロール',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('全て'),
                ),
                ...UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_getRoleDisplayName(role)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _filterSiteId,
              decoration: InputDecoration(
                labelText: 'サイト',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('全て'),
                ),
                ..._sitesMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filterSiteId = value;
                  _applyFilters();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final superAdminCount = _users.where((u) => u.role == UserRole.superAdmin).length;
    final siteAdminCount = _users.where((u) => u.role == UserRole.siteAdmin).length;
    final endUserCount = _users.where((u) => u.role == UserRole.endUser).length;
    final activeCount = _users.where((u) => u.isActive).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('総ユーザー数', _users.length.toString(), Colors.blue),
          _buildStatCard('スーパー管理者', superAdminCount.toString(), Colors.deepPurple),
          _buildStatCard('サイト管理者', siteAdminCount.toString(), Colors.orange),
          _buildStatCard('エンドユーザー', endUserCount.toString(), Colors.teal),
          _buildStatCard('アクティブ', activeCount.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ユーザーが見つかりません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final site = user.siteId != null ? _sitesMap[user.siteId] : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (!user.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Text(user.name),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getRoleDisplayName(user.role),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                if (site != null) Text('サイト: ${site.name}'),
                if (user.lastLoginAt != null)
                  Text(
                    '最終ログイン: ${_formatDate(user.lastLoginAt!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    _showEditUserDialog(user);
                    break;
                  case 'toggle_status':
                    await _toggleUserStatus(user);
                    break;
                  case 'reset_password':
                    _showResetPasswordDialog(user);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isActive ? '無効化' : '有効化'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, size: 20),
                      SizedBox(width: 8),
                      Text('パスワードリセット'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'ロール',
                border: OutlineInputBorder(),
              ),
              items: UserRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleDisplayName(role)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUser(user.id, {
                'name': nameController.text,
                'role': selectedRole.value,
              });
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードリセット'),
        content: Text('${user.email}にパスワードリセットメールを送信しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('パスワードリセットメールを送信しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー削除'),
        content: Text('${user.name}を削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteUser(user);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'isActive': !user.isActive,
      });
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isActive ? 'ユーザーを無効化しました' : 'ユーザーを有効化しました',
            ),
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

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報を更新しました'),
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

  Future<void> _deleteUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).delete();
      
      if (user.siteId != null) {
        await _firestore.collection('sites').doc(user.siteId).update({
          'currentUserCount': FieldValue.increment(-1),
        });
      }
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザーを削除しました'),
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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