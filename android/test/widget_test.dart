import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binerm_mention/live_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows sign-in screen when there is no saved session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BinerLiveApp());
    // The app intentionally contains repeating ambient animations, so do not
    // use pumpAndSettle: it can never settle while those animations are active.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
    expect(find.text('حساب نداری؟ ثبت‌نام کن'), findsOneWidget);

    // Dispose animated widgets and flush flutter_animate's zero-delay restart
    // callbacks so the fake-async test binding has no pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('switches the sign-in form to registration', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BinerLiveApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('حساب نداری؟ ثبت‌نام کن'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ساخت حساب'), findsOneWidget);
    expect(find.text('ایمیل'), findsOneWidget);
  });
}
