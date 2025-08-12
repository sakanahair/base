# Firebase Admin User Creation Instructions

## Option 1: Firebase Console (Easiest - Recommended)

1. Go to https://console.firebase.google.com/
2. Select project: **sakana-76364**
3. Navigate to **Authentication** > **Users**
4. Click **Add user**
5. Enter:
   - Email: `admin@sakana.hair`
   - Password: `Pass12345`
6. Click **Add user**

## Option 2: Using Service Account (Advanced)

1. Go to Firebase Console > Project Settings > Service Accounts
2. Click "Generate new private key"
3. Save the JSON file as `serviceAccountKey.json` in `/scripts` folder
4. Run:
   ```bash
   cd /Users/apple/DEV/SAKANA_AI/flutter/scripts
   node create_admin_with_key.js
   ```

## Option 3: Using gcloud CLI

1. Install gcloud CLI if not installed
2. Authenticate: `gcloud auth login`
3. Set project: `gcloud config set project sakana-76364`
4. Create user using Firebase Admin SDK with gcloud credentials

## Current Status

The Firebase project is properly configured:
- Project ID: sakana-76364
- Web App ID: 1:425845959532:web:d3b727b2141ab077ffe149
- Authentication is ready to use

You just need to:
1. Enable Email/Password sign-in method in Firebase Console
2. Create the admin@sakana.hair user using one of the methods above