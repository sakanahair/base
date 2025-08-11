import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyBKP5F4d35gR_z4LFJPyN_LKiJGnLJ5Uac',
    authDomain: 'sakana-admin.firebaseapp.com',
    projectId: 'sakana-admin',
    storageBucket: 'sakana-admin.appspot.com',
    messagingSenderId: '123456789',
    appId: '1:123456789:web:abcdef123456',
  );

  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(options: webOptions);
      } else {
        await Firebase.initializeApp();
      }
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }
}