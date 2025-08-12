import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// スーパー管理者の初期セットアップを行う
/// このメソッドは一度だけ実行してください
Future<void> setupSuperAdmin() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  const email = 'admin@sakana.hair';
  const password = 'Pass12345';
  
  try {
    print('Setting up super admin...');
    
    // 既存のユーザーでログイン
    UserCredential? credential;
    try {
      credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      print('Logged in with existing user');
    } catch (e) {
      print('Login error: $e');
      // ユーザーが存在しない場合は作成
      if (e.toString().contains('user-not-found')) {
        credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Created new user');
      }
    }
    
    if (credential != null && credential.user != null) {
      // ユーザー情報を設定
      await firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': 'Super Admin',
        'role': 'super_admin',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      
      print('Super admin document created/updated successfully');
      print('User ID: ${credential.user!.uid}');
    }
    
    // デフォルトサイトの作成
    final sitesQuery = await firestore.collection('sites').limit(1).get();
    if (sitesQuery.docs.isEmpty) {
      await firestore.collection('sites').add({
        'name': 'SAKANA HAIR 本店',
        'domain': 'sakana.hair',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': auth.currentUser?.uid,
        'settings': {
          'allowRegistration': true,
          'requireEmailVerification': false,
          'maxUsers': 100,
        },
        'adminIds': [auth.currentUser?.uid],
        'currentUserCount': 1,
      });
      
      print('Default site created');
    }
    
    await auth.signOut();
    print('Setup completed successfully');
  } catch (e) {
    print('Setup error: $e');
  }
}