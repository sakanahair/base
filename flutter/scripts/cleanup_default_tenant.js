#!/usr/bin/env node

/**
 * デフォルトテナントの画像をクリーンアップするスクリプト
 * tenants/default/services/ に誤って保存された画像を削除します
 */

const admin = require('firebase-admin');

// サービスアカウントキーのパスを指定
const serviceAccountPath = './service-account-key.json';

// Firebase Admin SDKを初期化
try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'sakana-76364.firebasestorage.app' // あなたのバケット名
  });
} catch (error) {
  console.error('❌ サービスアカウントキーが見つかりません');
  console.log('1. Firebase Console > プロジェクト設定 > サービスアカウント');
  console.log('2. 新しい秘密鍵を生成');
  console.log(`3. ${serviceAccountPath} として保存`);
  process.exit(1);
}

const bucket = admin.storage().bucket();

async function cleanupDefaultTenant() {
  console.log('🧹 デフォルトテナントのクリーンアップを開始...\n');
  
  try {
    // tenants/default/ 配下のファイルをリスト
    const [files] = await bucket.getFiles({
      prefix: 'tenants/default/'
    });
    
    if (files.length === 0) {
      console.log('✅ tenants/default/ に画像はありません');
      return;
    }
    
    console.log(`📁 ${files.length}個のファイルが見つかりました\n`);
    
    // ファイルを表示
    const filesByService = {};
    for (const file of files) {
      const match = file.name.match(/tenants\/default\/services\/([^\/]+)\//);
      if (match) {
        const serviceId = match[1];
        if (!filesByService[serviceId]) {
          filesByService[serviceId] = [];
        }
        filesByService[serviceId].push(file);
      }
    }
    
    // サービスごとにファイルを表示
    for (const [serviceId, serviceFiles] of Object.entries(filesByService)) {
      console.log(`Service ID: ${serviceId}`);
      for (const file of serviceFiles) {
        const metadata = file.metadata;
        const size = metadata.size ? (metadata.size / 1024).toFixed(2) + ' KB' : 'unknown';
        console.log(`  - ${file.name} (${size})`);
      }
      console.log('');
    }
    
    // 削除確認
    const readline = require('readline');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    const answer = await new Promise(resolve => {
      rl.question('これらのファイルを削除しますか？ (yes/no): ', resolve);
    });
    rl.close();
    
    if (answer.toLowerCase() !== 'yes') {
      console.log('❌ キャンセルしました');
      return;
    }
    
    // ファイルを削除
    console.log('\n🗑️ ファイルを削除中...');
    let deleteCount = 0;
    for (const file of files) {
      try {
        await file.delete();
        deleteCount++;
        process.stdout.write(`\r削除済み: ${deleteCount}/${files.length}`);
      } catch (error) {
        console.error(`\n❌ 削除失敗: ${file.name}`, error.message);
      }
    }
    
    console.log('\n\n✅ クリーンアップ完了！');
    console.log(`削除されたファイル: ${deleteCount}個`);
    
  } catch (error) {
    console.error('❌ エラー:', error);
  }
  
  process.exit(0);
}

// 実行
cleanupDefaultTenant();