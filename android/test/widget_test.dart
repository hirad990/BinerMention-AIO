import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binerm_mention/live_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows sign-in screen when there is no saved session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BinerLiveApp());
    await tester.pumpAndSettle();
    expect(find.text('BinerMention'), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
    expect(find.text('حساب نداری؟ ثبت‌نام کن'), findsOneWidget);
  });
}
