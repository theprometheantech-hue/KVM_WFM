import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_wfm_app/main.dart';
import 'package:kvm_wfm_app/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleTrackerApp());
    expect(find.byType(SimpleLoginScreen), findsOneWidget);
  });
}
