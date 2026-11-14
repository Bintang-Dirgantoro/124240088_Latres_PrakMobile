import 'package:flutter_test/flutter_test.dart';
import 'package:latian_responsi/main.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RickAndMortyApp(isLoggedIn: false));
    expect(find.text('Rick & Morty'), findsOneWidget);
    expect(find.text('Character Explorer'), findsOneWidget);
  });
}
