import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:klip_mobile/app.dart';
import 'package:klip_mobile/core/di/injection.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    await Hive.openBox<String>('projects');
    await setupLocator();
  });

  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KlipApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('projects');
    await Hive.deleteFromDisk();
  });
}
