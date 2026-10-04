import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for LucentVisit's registered mobile applications.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase App Check is only configured for the mobile application.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase App Check is only configured for Android and iOS.',
      ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDlENZDb7mbR-anAus9erQ_MvG31l11TA0',
    appId: '1:1018297282910:android:a6ac17ceeade943c109fcf',
    messagingSenderId: '1018297282910',
    projectId: 'lucentvisit',
    storageBucket: 'lucentvisit.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCjRXByXMxbvOxM91LDPNDjhYkbh13jf1k',
    appId: '1:1018297282910:ios:17fe72f792b5bb85109fcf',
    messagingSenderId: '1018297282910',
    projectId: 'lucentvisit',
    storageBucket: 'lucentvisit.firebasestorage.app',
    iosBundleId: 'org.clearvisit.clearvisit',
  );
}
