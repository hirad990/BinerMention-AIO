import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:binerm_mention/api_client.dart';
import 'package:binerm_mention/live_app.dart';
import 'package:binerm_mention/ui_kit.dart';
import 'package:binerm_mention/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  BinerApi? api;

  Future<void> pumpAuth(WidgetTester tester) async {
    api = BinerApi();
    await tester.pumpWidget(
      MaterialApp(
        home: LiveAuth(api: api!, onDone: () {}),
      ),
    );
    // The auth screen has ambient animations; pump a fixed duration rather
    // than pumpAndSettle so the test does not wait forever.
    await tester.pump(const Duration(milliseconds: 500));
  }

  tearDown(() {
    api?.dispose();
    api = null;
  });

  testWidgets('shows the current sign-in screen', (tester) async {
    await pumpAuth(tester);

    expect(find.text('ورود'), findsOneWidget);
    expect(find.text('ورود امن'), findsOneWidget);
    expect(find.text('حساب نداری؟ ثبت‌نام کن'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('switches the sign-in form to registration', (tester) async {
    await pumpAuth(tester);

    await tester.tap(find.text('حساب نداری؟ ثبت‌نام کن'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ساخت حساب'), findsOneWidget);
    expect(find.text('ایمیل'), findsOneWidget);
    expect(find.text('ثبت‌نام'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
  testWidgets('blur surface respects fast mode without losing its content', (tester) async {
    final preferences = BinerPreferences.instance;
    preferences.fastMode = true;
    await tester.pumpWidget(
      const MaterialApp(
        key: ValueKey('fast-mode'),
        home: Scaffold(
          body: BinerLiquidGlass(child: Text('surface content')),
        ),
      ),
    );
    expect(find.text('surface content'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);

    preferences.fastMode = false;
    await tester.pumpWidget(
      const MaterialApp(
        key: ValueKey('blur-mode'),
        home: Scaffold(
          body: BinerLiquidGlass(child: Text('surface content')),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    preferences.fastMode = false;
  });

}
