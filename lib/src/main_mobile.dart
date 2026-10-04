import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'app.dart';
import 'data/lucentvisit_database.dart';
import 'data/sql_lucentvisit_repository.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const androidDebugToken = String.fromEnvironment(
    'ANDROID_APP_CHECK_DEBUG_TOKEN',
  );
  const appleDebugToken = String.fromEnvironment('APPLE_APP_CHECK_DEBUG_TOKEN');
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider(
            debugToken: androidDebugToken == '' ? null : androidDebugToken,
          )
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider(
            debugToken: appleDebugToken == '' ? null : appleDebugToken,
          )
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  final database = await LucentVisitDatabase.open();
  final repository = SqlLucentVisitRepository(database);
  final notifications = NotificationService();
  await notifications.init();
  runApp(LucentVisitApp(repository: repository, reminders: notifications));
}
