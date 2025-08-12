// Firebase Admin SDK script to create admin user
// Run this script with Node.js after setting up Firebase Admin SDK

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You need to download the service account key from Firebase Console
// and save it as 'serviceAccountKey.json' in the same directory
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function createAdminUser() {
  try {
    const userRecord = await admin.auth().createUser({
      email: 'admin@sakana.hair',
      password: 'Pass12345',
      displayName: 'Admin User',
      emailVerified: true
    });
    
    console.log('Successfully created admin user:', userRecord.uid);
    
    // Optionally set custom claims for admin role
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      admin: true
    });
    
    console.log('Admin claims set successfully');
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('Admin user already exists');
      
      // Get the existing user and update password
      try {
        const user = await admin.auth().getUserByEmail('admin@sakana.hair');
        await admin.auth().updateUser(user.uid, {
          password: 'Pass12345'
        });
        console.log('Admin password updated successfully');
      } catch (updateError) {
        console.error('Error updating admin password:', updateError);
      }
    } else {
      console.error('Error creating admin user:', error);
    }
  }
  
  process.exit();
}

createAdminUser();