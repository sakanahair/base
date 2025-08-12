import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyCYujk7LtuPciwf4YT9qhi4_GqUbfqd9RY',
    authDomain: 'sakana-76364.firebaseapp.com',
    databaseURL: 'https://sakana-76364-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'sakana-76364',
    storageBucket: 'sakana-76364.firebasestorage.app',
    messagingSenderId: '425845959532',
    appId: '1:425845959532:web:d3b727b2141ab077ffe149',
    measurementId: 'G-W6FYPFVJ4X',
  );

  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(options: webOptions);
    } else {
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized successfully');
  }
}