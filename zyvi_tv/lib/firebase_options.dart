import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return ios;
    }
    return web;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBi5CpO6YMco94JdkHq2tTWLQyxwo7CIkU',
    appId: '1:836039862469:android:5a4b3c2d1e0f9a8b',
    messagingSenderId: '836039862469',
    projectId: 'zyvi-tv',
    storageBucket: 'zyvi-tv.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBi5CpO6YMco94JdkHq2tTWLQyxwo7CIkU',
    appId: '1:836039862469:ios:5a4b3c2d1e0f9a8b',
    messagingSenderId: '836039862469',
    projectId: 'zyvi-tv',
    storageBucket: 'zyvi-tv.firebasestorage.app',
    iosBundleId: 'com.example.zyvi-tv',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBi5CpO6YMco94JdkHq2tTWLQyxwo7CIkU',
    appId: '1:836039862469:web:aeb6b1ed21a101bff968ac',
    messagingSenderId: '836039862469',
    projectId: 'zyvi-tv',
    authDomain: 'zyvi-tv.firebaseapp.com',
    storageBucket: 'zyvi-tv.firebasestorage.app',
    measurementId: 'G-JHVYVB8W9Y',
  );
}
