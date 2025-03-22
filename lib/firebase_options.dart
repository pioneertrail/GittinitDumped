import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEMOKEY123456789',
    appId: '1:123456789:web:demo123456789',
    messagingSenderId: '123456789',
    projectId: 'safechat-demo-test',
    authDomain: 'safechat-demo-test.firebaseapp.com',
    databaseURL: 'https://safechat-demo-test-default-rtdb.firebaseio.com',
    storageBucket: 'safechat-demo-test.appspot.com',
  );
}
