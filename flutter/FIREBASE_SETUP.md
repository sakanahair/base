# Firebase Setup Instructions

## 1. Enable Email/Password Authentication

1. Go to https://console.firebase.google.com/
2. Select project: **sakana-76364**
3. Navigate to **Authentication** > **Sign-in method**
4. Enable **Email/Password** authentication
5. Click **Save**

## 2. Create Admin User

1. Go to **Authentication** > **Users**
2. Click **Add user**
3. Enter:
   - Email: `admin@sakana.hair`
   - Password: `Pass12345`
4. Click **Add user**

## Project Configuration

```javascript
// Firebase Config (already set in the app)
const firebaseConfig = {
  apiKey: "AIzaSyCYujk7LtuPciwf4YT9qhi4_GqUbfqd9RY",
  authDomain: "sakana-76364.firebaseapp.com",
  databaseURL: "https://sakana-76364-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "sakana-76364",
  storageBucket: "sakana-76364.firebasestorage.app",
  messagingSenderId: "425845959532",
  appId: "1:425845959532:web:d3b727b2141ab077ffe149",
  measurementId: "G-W6FYPFVJ4X"
};
```

## Test Authentication

After setup, you should be able to login at:
http://localhost:3000/admin/

Credentials:
- Email: admin@sakana.hair
- Password: Pass12345