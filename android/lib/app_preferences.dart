import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BinerPreferences extends ChangeNotifier {
  BinerPreferences._();
  static final BinerPreferences instance = BinerPreferences._();
  Locale locale = const Locale('fa');
  Color accent = const Color(0xFF54C8FF);
  bool fastMode = false;
  bool ready = false;
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final language = p.getString('biner_language') ?? 'fa';
    locale = Locale(['fa','en','ar','tr'].contains(language) ? language : 'fa');
    accent = Color(p.getInt('biner_accent') ?? 0xFF54C8FF);
    fastMode = p.getBool('biner_fast_mode') ?? false;
    ready = true; notifyListeners();
  }
  Future<void> setLanguage(String code) async {
    if (!['fa','en','ar','tr'].contains(code)) return;
    locale = Locale(code); final p = await SharedPreferences.getInstance();
    await p.setString('biner_language', code); notifyListeners();
  }
  Future<void> setAccent(Color color) async {
    accent = color; final p = await SharedPreferences.getInstance();
    await p.setInt('biner_accent', color.toARGB32()); notifyListeners();
  }
  Future<void> setFastMode(bool enabled) async {
    fastMode = enabled; final p = await SharedPreferences.getInstance();
    await p.setBool('biner_fast_mode', enabled); notifyListeners();
  }
  TextDirection get direction => locale.languageCode == 'fa' || locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
}
String binerText(String fa, {String? en, String? ar, String? tr}) {
  switch (BinerPreferences.instance.locale.languageCode) {
    case 'en': return en ?? fa;
    case 'ar': return ar ?? en ?? fa;
    case 'tr': return tr ?? en ?? fa;
    default: return fa;
  }
}
