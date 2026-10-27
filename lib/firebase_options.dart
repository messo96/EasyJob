// File generated for Firebase project: findmyjob-510711
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String firestoreDatabaseId =
      'ai-studio-84bebce4-f4b1-49e3-8af6-05d957018bc3';
  static const String googleOAuthClientId =
      '1091567483148-vdjt5flrlmjqoj9669b4apurm49lpo1k.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5q0Z4z7XEPTXYYz-RprsxCc0LW4djylo',
    appId: '1:1091567483148:web:885480c009ea0354b37129',
    messagingSenderId: '1091567483148',
    projectId: 'findmyjob-510711',
    authDomain: 'findmyjob-510711.firebaseapp.com',
    storageBucket: 'findmyjob-510711.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqkfgqQqu8qcSV4ZeBSRlVtiJcTuodZ_I',
    appId: '1:1091567483148:android:6994b13c043266a5b37129',
    messagingSenderId: '1091567483148',
    projectId: 'findmyjob-510711',
    storageBucket: 'findmyjob-510711.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5q0Z4z7XEPTXYYz-RprsxCc0LW4djylo',
    appId: '1:1091567483148:ios:885480c009ea0354b37129',
    messagingSenderId: '1091567483148',
    projectId: 'findmyjob-510711',
    storageBucket: 'findmyjob-510711.firebasestorage.app',
  );
}
