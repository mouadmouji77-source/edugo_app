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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsbGSJZoA7k9RiPjdTPPbfs4GUzO6KEAM',
    appId: '1:728542508352:web:c5ad68a1f5f5a2079876a5',
    messagingSenderId: '728542508352',
    projectId: 'edugo-a78a0',
    authDomain: 'edugo-a78a0.firebaseapp.com',
    databaseURL: 'https://edugo-a78a0-default-rtdb.firebaseio.com',
    storageBucket: 'edugo-a78a0.firebasestorage.app',
    measurementId: 'G-CZBTLKR9P2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7TfnvGPerc9ZTCNEYVSgMJb0YJII6mI0',
    appId: '1:728542508352:android:4e5a4a66a22c13359876a5',
    messagingSenderId: '728542508352',
    projectId: 'edugo-a78a0',
    databaseURL: 'https://edugo-a78a0-default-rtdb.firebaseio.com',
    storageBucket: 'edugo-a78a0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqhF_77SDfk04vRHV5RBfgnIXuCD4_k4I',
    authDomain: 'edugo-a78a0.firebaseapp.com',
    databaseURL: 'https://edugo-a78a0-default-rtdb.firebaseio.com',
    projectId: 'edugo-a78a0',
    storageBucket: 'edugo-a78a0.firebasestorage.app',
    messagingSenderId: '728542508352',
    appId: '1:728542508352:ios:027465a48e0031939876a5',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqhF_77SDfk04vRHV5RBfgnIXuCD4_k4I',
    authDomain: 'edugo-a78a0.firebaseapp.com',
    databaseURL: 'https://edugo-a78a0-default-rtdb.firebaseio.com',
    projectId: 'edugo-a78a0',
    storageBucket: 'edugo-a78a0.firebasestorage.app',
    messagingSenderId: '728542508352',
    appId: '1:728542508352:ios:027465a48e0031939876a5',
  );
}