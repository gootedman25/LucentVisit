import 'package:firebase_app_check/firebase_app_check.dart';

Future<String?> getAppCheckToken() => FirebaseAppCheck.instance.getToken();
