import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';

// ponytail: add Firebase/analytics init, crash reporting, etc.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await Hive.initFlutter();

  // Initialize dependency injection
  await setupLocator();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const KlipApp());
}
