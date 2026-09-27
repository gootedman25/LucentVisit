import 'package:flutter/material.dart';

import 'app.dart';
import 'data/browser_lucentvisit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = BrowserLucentVisitRepository();
  runApp(LucentVisitApp(repository: repository));
}
