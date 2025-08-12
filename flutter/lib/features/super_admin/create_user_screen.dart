import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/enhanced_auth_service.dart';
import '../../core/services/multi_tenant_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/site_model.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  UserRole _selectedRole = UserRole.endUser;
  SiteModel? _selectedSite;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<EnhancedAuthService>(context);
    final multiTenantService = Provider.of<MultiTenantService>(context);
    
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
        title: const Text('新規ユーザー作成'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '基本情報',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '氏名',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '氏名を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!value.contains('@')) {
                            return '有効なメールアドレスを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'パスワード',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          if (value.length < 6) {
                            return 'パスワードは6文字以上で設定してください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '権限設定',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'ユーザーロール',
                          prefixIcon: Icon(Icons.security),
                          border: OutlineInputBorder(),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(_getRoleDisplayName(role)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            if (value == UserRole.superAdmin) {
                              _selectedSite = null;
                            }
                          });
                        },
                      ),
                      if (_selectedRole != UserRole.superAdmin) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<SiteModel>(
                          value: _selectedSite,
                          decoration: const InputDecoration(
                            labelText: '所属サイト',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: multiTenantService.managedSites.map((site) {
                            return DropdownMenuItem(
                              value: site,
                              child: Text(site.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSite = value;
                            });
                          },
                          validator: (value) {
                            if (_selectedRole != UserRole.superAdmin && value == null) {
                              return 'サイトを選択してください';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'ロールの説明',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRoleDescription(UserRole.superAdmin, 
                        '全システムの管理権限を持ちます'),
                      _buildRoleDescription(UserRole.siteAdmin, 
                        '特定サイトの管理権限を持ちます'),
                      _buildRoleDescription(UserRole.endUser, 
                        'サイト内の一般ユーザーです'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ユーザーを作成',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDescription(UserRole role, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${_getRoleDisplayName(role)}:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
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

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<EnhancedAuthService>(
        context,
        listen: false,
      );

      final result = await authService.register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        siteId: _selectedSite?.id,
        role: _selectedRole,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザーを作成しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'ユーザー作成に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}