import 'package:flutter_test/flutter_test.dart';
import 'package:klip_mobile/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KlipApp());
    expect(find.text('AI YouTube Clipper'), findsOneWidget);
  });
}
