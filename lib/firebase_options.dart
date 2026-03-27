// Firebase client options are loaded from `assets/env/firebase.env` at startup.
// Run `flutterfire configure` then copy `assets/env/firebase.env.example`.
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client config from `.env`. Not a substitute for Security Rules or App Check.
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for linux — '
          'add linux keys to .env or exclude the linux target.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _required('FIREBASE_WEB_API_KEY'),
        appId: _required('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required('FIREBASE_PROJECT_ID'),
        authDomain: _required('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _required('FIREBASE_ANDROID_API_KEY'),
        appId: _required('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required('FIREBASE_PROJECT_ID'),
        storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _required('FIREBASE_IOS_API_KEY'),
        appId: _required('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required('FIREBASE_PROJECT_ID'),
        storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _required('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _or('FIREBASE_MACOS_API_KEY', 'FIREBASE_IOS_API_KEY'),
        appId: _or('FIREBASE_MACOS_APP_ID', 'FIREBASE_IOS_APP_ID'),
        messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required('FIREBASE_PROJECT_ID'),
        storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _or('FIREBASE_MACOS_BUNDLE_ID', 'FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _required('FIREBASE_WINDOWS_API_KEY'),
        appId: _required('FIREBASE_WINDOWS_APP_ID'),
        messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required('FIREBASE_PROJECT_ID'),
        authDomain: _required('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
      );

  static String _required(String name) {
    final v = dotenv.env[name]?.trim();
    if (v == null || v.isEmpty) {
      throw StateError(
        'Missing "$name" in assets/env/firebase.env — copy firebase.env.example '
        'to firebase.env and fill values from Firebase (Project settings / '
        'flutterfire configure).',
      );
    }
    return v;
  }

  static String _or(String primary, String fallback) {
    final v = dotenv.env[primary]?.trim();
    if (v != null && v.isNotEmpty) return v;
    return _required(fallback);
  }
}
