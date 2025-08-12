const admin = require('firebase-admin');

// Firebaseプロジェクトの初期化
// サービスアカウントキーを使用する場合はコメントを外してください
// const serviceAccount = require('./serviceAccountKey.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   projectId: 'sakana'
// });

// デフォルトの認証情報を使用（Firebase CLIでログイン済みの場合）
admin.initializeApp({
  projectId: 'sakana'
});

async function createAdminUser() {
  try {
    const userRecord = await admin.auth().createUser({
      email: 'admin@sakana.hair',
      password: 'Pass12345',
      displayName: 'Admin User',
      emailVerified: true
    });
    
    console.log('✅ Successfully created admin user:', userRecord.uid);
    console.log('Email:', userRecord.email);
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('⚠️  Admin user already exists');
      
      // 既存ユーザーのパスワードを更新
      try {
        const user = await admin.auth().getUserByEmail('admin@sakana.hair');
        await admin.auth().updateUser(user.uid, {
          password: 'Pass12345'
        });
        console.log('✅ Admin password updated successfully');
      } catch (updateError) {
        console.error('❌ Error updating admin password:', updateError.message);
      }
    } else {
      console.error('❌ Error creating admin user:', error.message);
    }
  }
  
  process.exit();
}

createAdminUser();