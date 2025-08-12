const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Check if service account key exists
const keyPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('❌ serviceAccountKey.json not found!');
  console.log('\n📝 Instructions:');
  console.log('1. Go to https://console.firebase.google.com/');
  console.log('2. Select project: sakana-76364');
  console.log('3. Go to Project Settings > Service Accounts');
  console.log('4. Click "Generate new private key"');
  console.log('5. Save the file as serviceAccountKey.json in this scripts folder');
  console.log('6. Run this script again');
  process.exit(1);
}

// Initialize with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sakana-76364'
});

async function createAdminUser() {
  try {
    const userRecord = await admin.auth().createUser({
      email: 'admin@sakana.hair',
      password: 'Pass12345',
      emailVerified: true,
      displayName: 'Admin User'
    });
    
    console.log('✅ Successfully created admin user!');
    console.log('   UID:', userRecord.uid);
    console.log('   Email:', userRecord.email);
    console.log('\n🎉 You can now login with:');
    console.log('   Email: admin@sakana.hair');
    console.log('   Password: Pass12345');
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('⚠️  User admin@sakana.hair already exists');
      
      try {
        const user = await admin.auth().getUserByEmail('admin@sakana.hair');
        await admin.auth().updateUser(user.uid, {
          password: 'Pass12345'
        });
        console.log('✅ Password updated for existing user');
        console.log('   UID:', user.uid);
        console.log('\n🎉 You can now login with:');
        console.log('   Email: admin@sakana.hair');
        console.log('   Password: Pass12345');
      } catch (updateError) {
        console.error('❌ Could not update password:', updateError.message);
      }
    } else {
      console.error('❌ Error:', error.message);
    }
  }
  
  process.exit(0);
}

createAdminUser();