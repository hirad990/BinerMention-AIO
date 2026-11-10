import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:binerm_mention/app_preferences.dart';
import 'package:binerm_mention/localized_text.dart';

void main() {
  final preferences = BinerPreferences.instance;

  tearDown(() {
    preferences.locale = const Locale('fa');
  });

  test('bundled UI copy switches completely between supported locales', () {
    preferences.locale = const Locale('en');
    expect(binerText('پیام‌ها'), 'Messages');
    expect(binerText('پست‌های ذخیره‌شده'), 'Saved posts');

    preferences.locale = const Locale('ar');
    expect(binerText('پیام‌ها'), 'الرسائل');
    expect(preferences.direction, TextDirection.rtl);

    preferences.locale = const Locale('tr');
    expect(binerText('پیام‌ها'), 'Mesajlar');
    expect(preferences.direction, TextDirection.ltr);

    preferences.locale = const Locale('fa');
    expect(binerText('پیام‌ها'), 'پیام‌ها');
    expect(preferences.direction, TextDirection.rtl);
  });

  test('dynamic UI counts are localized without network access', () {
    preferences.locale = const Locale('en');
    expect(binerText('12 دقیقه'), '12 min');
    expect(binerText('3 ساعت و 15 دقیقه'), '3 hr 15 min');

    preferences.locale = const Locale('ar');
    expect(binerText('12 دقیقه'), '12 دقيقة');

    preferences.locale = const Locale('tr');
    expect(binerText('12 دقیقه'), '12 dk');
  });

  testWidgets('localized text widget renders the selected language', (tester) async {
    preferences.locale = const Locale('en');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BinerLocalizedText('پست‌های ذخیره‌شده')),
      ),
    );
    expect(find.text('Saved posts'), findsOneWidget);
  });
}
