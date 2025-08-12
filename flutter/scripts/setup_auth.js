const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin
initializeApp({
  projectId: 'sakana-76364'
});

async function setupAuth() {
  const auth = getAuth();
  
  try {
    // Create admin user
    console.log('Creating admin user...');
    const userRecord = await auth.createUser({
      email: 'admin@sakana.hair',
      password: 'Pass12345',
      emailVerified: true,
      displayName: 'Admin User'
    });
    
    console.log('✅ Successfully created admin user:');
    console.log('   UID:', userRecord.uid);
    console.log('   Email:', userRecord.email);
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('⚠️  Admin user already exists');
      
      try {
        // Get existing user and update password
        const user = await auth.getUserByEmail('admin@sakana.hair');
        await auth.updateUser(user.uid, {
          password: 'Pass12345',
          emailVerified: true
        });
        console.log('✅ Admin user password updated');
        console.log('   UID:', user.uid);
      } catch (updateError) {
        console.error('❌ Error updating user:', updateError.message);
      }
    } else {
      console.error('❌ Error creating user:', error.message);
    }
  }
}

setupAuth().then(() => process.exit(0));