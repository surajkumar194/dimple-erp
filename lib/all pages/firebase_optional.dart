import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are configured only for Android and Web. '
      'Current platform: $defaultTargetPlatform',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
  apiKey: "AIzaSyCad4utyQ612FprvBZLPfHTB6j6afht76g",
  appId: "1:746844572775:web:418e56e71f4873bff118c2",
  messagingSenderId: "746844572775",
    projectId: 'pushnotification-f5b52',
  );

  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyCad4utyQ612FprvBZLPfHTB6j6afht76g",
  authDomain: "pushnotification-f5b52.firebaseapp.com",
  databaseURL: "https://pushnotification-f5b52-default-rtdb.firebaseio.com",
  projectId: "pushnotification-f5b52",
  storageBucket: "pushnotification-f5b52.appspot.com",
  messagingSenderId: "746844572775",
  appId: "1:746844572775:web:418e56e71f4873bff118c2",
  measurementId: "G-WSRZW509SW"
  );
}




// const firebaseConfig = {
//   apiKey: "AIzaSyB6yzxKAGqsUi5QQNI4TNAERoxXQYaoHNg",
//   authDomain: "dimple-erp.firebaseapp.com",
//   projectId: "dimple-erp",
//   storageBucket: "dimple-erp.firebasestorage.app",
//   messagingSenderId: "884602219793",
//   appId: "1:884602219793:web:a1076fb2ae675f9b79b0b0",
//   measurementId: "G-G7588MGBY5"
// };



// const firebaseConfig = {
//   apiKey: "AIzaSyCad4utyQ612FprvBZLPfHTB6j6afht76g",
//   authDomain: "pushnotification-f5b52.firebaseapp.com",
//   databaseURL: "https://pushnotification-f5b52-default-rtdb.firebaseio.com",
//   projectId: "pushnotification-f5b52",
//   storageBucket: "pushnotification-f5b52.appspot.com",
//   messagingSenderId: "746844572775",
//   appId: "1:746844572775:web:418e56e71f4873bff118c2",
//   measurementId: "G-WSRZW509SW"
// };
//npm install -g firebase-tools
// firebase login
// firebase init
// firebase deploy