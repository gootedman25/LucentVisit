import 'package:flutter/material.dart';

import 'app.dart';
import 'data/lucentvisit_database.dart';
import 'data/sql_lucentvisit_repository.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await LucentVisitDatabase.open();
  final repository = SqlLucentVisitRepository(database);
  final notifications = NotificationService();
  await notifications.init();
  runApp(LucentVisitApp(repository: repository, reminders: notifications));
}
