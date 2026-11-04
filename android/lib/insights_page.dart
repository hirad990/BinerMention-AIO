import 'package:flutter/material.dart';
import 'api_client.dart';
import 'ui_kit.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.api});
  final BinerApi api;
  @override State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late Future<Map<String, dynamic>> _future;
  @override void initState() { super.initState(); _future = widget.api.insights(); }

  Future<void> _reload() async {
    final next = widget.api.insights();
    setState(() => _future = next);
    await next;
  }

  String _number(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) return '—';
    return parsed.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '٬');
  }

  String _readingTime(dynamic raw) {
    final ms = int.tryParse(raw?.toString() ?? '') ?? 0;
    if (ms <= 0) return 'هنوز داده‌ای ثبت نشده';
    final minutes = (ms / 60000).floor();
    if (minutes < 1) return 'کمتر از یک دقیقه';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$minutes دقیقه';
    return rest == 0 ? '$hours ساعت' : '$hours ساعت و $rest دقیقه';
  }

  Widget _stat({required String title, required dynamic value, required IconData icon, required Color color}) {
    return BinerSurfaceCard(
      accent: color, radius: 20, padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 19)),
          const Spacer(),
          Icon(Icons.trending_up_rounded, color: color.withValues(alpha: .55), size: 17),
        ]),
        const SizedBox(height: 15),
        AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: Text(_number(value), key: ValueKey(value?.toString() ?? 'empty'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.6))),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _miniMetric(IconData icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
    const SizedBox(width: 5),
    Text(value, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
  ]);

  Widget _topPost(Map post, int index) => BinerSurfaceCard(
    margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(15), radius: 19,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)), child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900))),
        const SizedBox(width: 9),
        Expanded(child: Text('@${post['username'] ?? 'user'}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
        const Icon(Icons.insights_rounded, size: 17, color: Colors.grey),
      ]),
      const SizedBox(height: 10),
      Text(post['body']?.toString() ?? '', maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.55)),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 8, children: [
        _miniMetric(Icons.favorite_border_rounded, _number(post['likes_count'])),
        _miniMetric(Icons.repeat_rounded, _number(post['reposts_count'])),
        _miniMetric(Icons.mode_comment_outlined, _number(post['replies_count'])),
      ]),
    ]),
  );

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Biner Insights'), actions: [IconButton(tooltip: 'به‌روزرسانی آمار', onPressed: _reload, icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return ListView(children: const [BinerSkeleton(lines: 2), BinerSkeleton(lines: 2), BinerSkeleton(lines: 2)]);
        if (snapshot.hasError) return BinerEmptyState(
          icon: Icons.cloud_off_rounded, title: 'آمار بارگذاری نشد',
          description: 'اتصال به سرور یا دسترسی API را بررسی کن و دوباره تلاش کن.',
          action: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
        );
        final data = snapshot.data ?? const <String, dynamic>{};
        final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : <String, dynamic>{};
        final top = (data['top_posts'] as List? ?? const []).whereType<Map>().toList();
        final entries = <(String, String, IconData, Color)>[
          ('پست‌های منتشرشده', 'posts', Icons.article_outlined, const Color(0xFF54C8FF)),
          ('دنبال‌کنندگان', 'followers', Icons.people_alt_outlined, const Color(0xFF9B8CFF)),
          ('لایک دریافتی', 'likes_received', Icons.favorite_border_rounded, const Color(0xFFFF78B8)),
          ('بازنشر دریافتی', 'reposts_received', Icons.repeat_rounded, const Color(0xFF27C995)),
          ('کامنت دریافتی', 'comments_received', Icons.chat_bubble_outline_rounded, const Color(0xFFFFB45E)),
          ('بازدید ثبت‌شده', 'views', Icons.visibility_outlined, const Color(0xFF54C8FF)),
        ];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              BinerSurfaceCard(
                radius: 26, padding: const EdgeInsets.all(10), accent: const Color(0xFF54C8FF),
                child: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF102B45), Color(0xFF211A45)]), borderRadius: BorderRadius.all(Radius.circular(18))),
                  padding: const EdgeInsets.all(18),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.insights_rounded, color: Color(0xFF54C8FF)), SizedBox(width: 9), Text('نمای کلی حساب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
                    SizedBox(height: 8),
                    Text('آمار از رویدادهای ثبت‌شده در BinerMention محاسبه می‌شود؛ هر شاخص باید قابل ردیابی و توضیح باشد.', style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 19),
              BinerSectionHeader(title: 'عملکرد حساب', subtitle: 'مجموع داده‌های ثبت‌شده تا این لحظه'),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 3 : 2;
                final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final item in entries) SizedBox(width: width, child: _stat(title: item.$1, value: stats[item.$2], icon: item.$3, color: item.$4)),
                ]);
              }),
              const SizedBox(height: 18),
              const BinerSectionHeader(title: 'زمان مطالعه', subtitle: 'مجموع زمان تعامل ثبت‌شده با پست‌های عمومی تو'),
              BinerSurfaceCard(child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF9B8CFF).withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.schedule_rounded, color: Color(0xFF9B8CFF))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_readingTime(stats['reading_time_ms']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('این شاخص از زمان فعال‌شدن ثبت رویدادها معتبر است.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.4)),
                ])),
              ])),
              const SizedBox(height: 20),
              const BinerSectionHeader(title: 'پست‌های پربازده', subtitle: 'بر اساس لایک، بازنشر و کامنت'),
              if (top.isEmpty) BinerEmptyState(icon: Icons.query_stats_rounded, title: 'هنوز دادهٔ کافی نداریم', description: 'با انتشار پست و دریافت تعامل، این بخش به‌تدریج کامل می‌شود.')
              else ...top.asMap().entries.map((entry) => _topPost(entry.value, entry.key)),
              const SizedBox(height: 10),
              BinerSurfaceCard(accent: const Color(0xFF9B8CFF), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF9B8CFF), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(data['transparency_note']?.toString() ?? 'آمار فقط از داده‌های ذخیره‌شده در سامانه محاسبه می‌شود.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.65))),
              ])),
            ],
          ),
        );
      },
    ),
  );
}
