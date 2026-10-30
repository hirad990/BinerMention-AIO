import 'dart:convert';
import 'package:http/http.dart' as http;

class BinerTextTools {
  static String summarize(String input, {int maxSentences = 3}) {
    final text = input.trim();
    if (text.length < 220) return text;
    final sentences = text.split(RegExp(r'(?<=[.!?؟۔])\s+')).where((s) => s.trim().length > 18).toList();
    if (sentences.length <= maxSentences) return text;
    final words = RegExp(r'[\p{L}\p{N}]{3,}', unicode: true).allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();
    final frequency = <String,int>{};
    for (final word in words) { frequency[word] = (frequency[word] ?? 0) + 1; }
    final scored = <({int index, double score, String sentence})>[];
    for (var i=0;i<sentences.length;i++) {
      final tokens = RegExp(r'[\p{L}\p{N}]{3,}', unicode: true).allMatches(sentences[i].toLowerCase()).map((m) => m.group(0)!);
      final score = tokens.fold<double>(0, (sum, word) => sum + (frequency[word] ?? 0)) / (tokens.length + 1);
      scored.add((index:i,score:score,sentence:sentences[i].trim()));
    }
    scored.sort((a,b)=>b.score.compareTo(a.score));
    final chosen = scored.take(maxSentences).toList()..sort((a,b)=>a.index.compareTo(b.index));
    return chosen.map((x)=>x.sentence).join(' ');
  }
  static Future<String> translate(String text, String targetLanguage) async {
    if (text.trim().isEmpty) return text;
    final uri = Uri.https('api.mymemory.translated.net', '/get', {'q': text, 'langpair': 'autodetect|$targetLanguage'});
    final response = await http.get(uri, headers: {'Accept':'application/json'}).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) throw Exception('سرویس ترجمه در دسترس نیست.');
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String,dynamic>;
    final translated = (data['responseData'] as Map?)?['translatedText']?.toString();
    if (translated == null || translated.isEmpty) throw Exception('ترجمه‌ای دریافت نشد.');
    return translated;
  }
}
