import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'app.dart';
import 'data/browser_lucentvisit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaEnterpriseProvider(
      '6LcReOItAAAAAPeCp7vzN7qI0H1KRSQN0XTAN5yp',
    ),
  );
  final repository = BrowserLucentVisitRepository();
  runApp(LucentVisitApp(repository: repository));
}
