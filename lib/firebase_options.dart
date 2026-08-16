import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCU8Fyf-utafR7dEKLM2sOkKN03jmdbvmM',
    appId: '1:1083808569581:web:dbebdc75c9c95b507d54e4',
    messagingSenderId: '1083808569581',
    projectId: 'final-chagas-app',
    authDomain: 'final-chagas-app.firebaseapp.com',
    storageBucket: 'final-chagas-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCU8Fyf-utafR7dEKLM2sOkKN03jmdbvmM',
    appId: '1:1083808569581:android:dbebdc75c9c95b507d54e4',
    messagingSenderId: '1083808569581',
    projectId: 'final-chagas-app',
    storageBucket: 'final-chagas-app.firebasestorage.app',
  );
}
