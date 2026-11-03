import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_client.dart';

const _blue = Color(0xFF54C8FF);
const _violet = Color(0xFF9B8CFF);

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.api});
  final BinerApi api;
  @override State<InsightsPage> createState() => _InsightsPageState();
}
class _InsightsPageState extends State<InsightsPage> {
  late Future<Map<String, dynamic>> _future;
  @override void initState() { super.initState(); _future = widget.api.insights(); }
  void _reload() => setState(() => _future = widget.api.insights());

  Widget _stat(String title, dynamic value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xE6101A2A) : Colors.white,
      borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22), const SizedBox(height: 14),
      Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3), Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Biner Insights', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _reload, child: const Text('تلاش دوباره'))])));
        final data = snapshot.data ?? {};
        final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : <String, dynamic>{};
        final top = (data['top_posts'] as List? ?? const []).whereType<Map>().toList();
        final entries = <(String, String, IconData, Color)>[
          ('پست‌های منتشرشده', 'posts', Icons.article_outlined, _blue),
          ('دنبال‌کنندگان', 'followers', Icons.people_alt_outlined, _violet),
          ('لایک دریافتی', 'likes_received', Icons.favorite_border_rounded, const Color(0xFFFF78B8)),
          ('بازنشر دریافتی', 'reposts_received', Icons.repeat_rounded, const Color(0xFF27C995)),
          ('کامنت دریافتی', 'comments_received', Icons.chat_bubble_outline_rounded, const Color(0xFFFFB45E)),
          ('بازدید ثبت‌شده', 'views', Icons.visibility_outlined, _blue),
        ];
        return RefreshIndicator(onRefresh: () async => _reload(), child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF102B45), Color(0xFF211A45)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.insights_rounded, color: _blue), SizedBox(width: 8), Text('آمار حساب تو', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
            SizedBox(height: 8), Text('نمایی روشن از تعاملات ثبت‌شده؛ بدون عددسازی و با مشخص‌کردن محدودیت داده‌ها.', style: TextStyle(color: Colors.white70, height: 1.6)),
          ])).animate().fadeIn(duration: 250.ms),
          const SizedBox(height: 14),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55, children: [for (final e in entries) _stat(e.$1, stats[e.$2], e.$3, e.$4)]),
          const SizedBox(height: 18),
          const Text('پست‌های پربازده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (top.isEmpty) const Text('هنوز دادهٔ کافی برای رتبه‌بندی پست‌ها وجود ندارد.', style: TextStyle(color: Colors.grey))
          else ...top.map((p) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _blue.withValues(alpha: .15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['body']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8), Text('♥ ${p['likes_count'] ?? 0}   ↻ ${p['reposts_count'] ?? 0}   ◌ ${p['replies_count'] ?? 0}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]))),
          const SizedBox(height: 10),
          Text(data['transparency_note']?.toString() ?? 'آمار از داده‌های ذخیره‌شده در سامانه محاسبه می‌شود.', style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.7)),
          Text('زمان مطالعه: ${((int.tryParse(stats['reading_time_ms']?.toString() ?? '0') ?? 0) / 60000).toStringAsFixed(1)} دقیقهٔ ثبت‌شده', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]));
      },
    ),
  );
}
