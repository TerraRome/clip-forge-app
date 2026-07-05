import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

// ponytail: add Firebase/analytics init, crash reporting, etc.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const KlipApp());
}
