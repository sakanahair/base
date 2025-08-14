#!/usr/bin/env node

/**
 * Firebase Storage クリーンアップスクリプト
 * 不要な画像（temp_IDや削除済みサービス）を削除します
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json'); // Firebase Admin SDKの秘密鍵

// Firebase Admin SDKを初期化
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'sakana-pocket.appspot.com' // あなたのバケット名に変更
});

const bucket = admin.storage().bucket();
const firestore = admin.firestore();

async function cleanupStorage() {
  console.log('🧹 Firebase Storage クリーンアップを開始...');
  
  try {
    // 1. すべてのテナントを取得
    const tenantsSnapshot = await firestore.collection('tenants').get();
    const tenantIds = tenantsSnapshot.docs.map(doc => doc.id);
    console.log(`📁 ${tenantIds.length}個のテナントを処理します`);
    
    for (const tenantId of tenantIds) {
      console.log(`\n👤 テナント: ${tenantId}`);
      
      // 2. 有効なサービスIDを取得
      const servicesSnapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('services')
        .get();
      
      const validServiceIds = new Set(servicesSnapshot.docs.map(doc => doc.id));
      console.log(`  ✅ 有効なサービス: ${validServiceIds.size}個`);
      
      // 3. Storage内のファイルをチェック
      const [files] = await bucket.getFiles({
        prefix: `tenants/${tenantId}/services/`
      });
      
      const serviceIdPattern = /tenants\/[^\/]+\/services\/([^\/]+)\//;
      const filesGroupedByService = {};
      
      // サービスIDごとにファイルをグループ化
      for (const file of files) {
        const match = file.name.match(serviceIdPattern);
        if (match) {
          const serviceId = match[1];
          if (!filesGroupedByService[serviceId]) {
            filesGroupedByService[serviceId] = [];
          }
          filesGroupedByService[serviceId].push(file);
        }
      }
      
      // 4. 削除対象を特定
      let deleteCount = 0;
      for (const [serviceId, serviceFiles] of Object.entries(filesGroupedByService)) {
        // temp_で始まるIDまたは存在しないサービスのファイルを削除
        if (serviceId.startsWith('temp_') || !validServiceIds.has(serviceId)) {
          console.log(`  🗑️ 削除対象: ${serviceId} (${serviceFiles.length}ファイル)`);
          
          for (const file of serviceFiles) {
            try {
              await file.delete();
              deleteCount++;
            } catch (error) {
              console.error(`    ❌ 削除失敗: ${file.name}`, error.message);
            }
          }
        }
      }
      
      // 5. tempフォルダもクリーンアップ
      const [tempFiles] = await bucket.getFiles({
        prefix: `tenants/${tenantId}/temp/`
      });
      
      if (tempFiles.length > 0) {
        console.log(`  🗑️ tempフォルダ: ${tempFiles.length}ファイル`);
        for (const file of tempFiles) {
          try {
            await file.delete();
            deleteCount++;
          } catch (error) {
            console.error(`    ❌ 削除失敗: ${file.name}`, error.message);
          }
        }
      }
      
      console.log(`  ✨ ${deleteCount}個のファイルを削除しました`);
    }
    
    console.log('\n✅ クリーンアップ完了！');
    
  } catch (error) {
    console.error('❌ エラー:', error);
  }
  
  process.exit(0);
}

// ドライラン機能（削除せずにリストのみ表示）
async function dryRun() {
  console.log('🔍 ドライラン実行中（削除せずにリストのみ表示）...');
  
  try {
    const tenantsSnapshot = await firestore.collection('tenants').get();
    const tenantIds = tenantsSnapshot.docs.map(doc => doc.id);
    
    for (const tenantId of tenantIds) {
      console.log(`\n👤 テナント: ${tenantId}`);
      
      const servicesSnapshot = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('services')
        .get();
      
      const validServiceIds = new Set(servicesSnapshot.docs.map(doc => doc.id));
      
      const [files] = await bucket.getFiles({
        prefix: `tenants/${tenantId}/services/`
      });
      
      const serviceIdPattern = /tenants\/[^\/]+\/services\/([^\/]+)\//;
      const toDelete = [];
      
      for (const file of files) {
        const match = file.name.match(serviceIdPattern);
        if (match) {
          const serviceId = match[1];
          if (serviceId.startsWith('temp_') || !validServiceIds.has(serviceId)) {
            toDelete.push({
              serviceId,
              fileName: file.name,
              size: (file.metadata.size / 1024).toFixed(2) + ' KB'
            });
          }
        }
      }
      
      if (toDelete.length > 0) {
        console.log('  削除対象ファイル:');
        toDelete.forEach(file => {
          console.log(`    - ${file.fileName} (${file.size})`);
        });
        console.log(`  合計: ${toDelete.length}ファイル`);
      } else {
        console.log('  削除対象なし');
      }
    }
    
  } catch (error) {
    console.error('❌ エラー:', error);
  }
  
  process.exit(0);
}

// コマンドライン引数をチェック
const args = process.argv.slice(2);
if (args.includes('--dry-run')) {
  dryRun();
} else if (args.includes('--cleanup')) {
  cleanupStorage();
} else {
  console.log(`
使い方:
  node cleanup_firebase_storage.js --dry-run    # 削除対象をリスト表示（削除しない）
  node cleanup_firebase_storage.js --cleanup    # 実際に削除を実行

注意: 
  1. service-account-key.json ファイルが必要です
  2. Firebase Admin SDKの権限が必要です
  3. --cleanupは実際にファイルを削除します！
  `);
  process.exit(1);
}