import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_client.dart';
import 'ui_kit.dart';
import 'app_preferences.dart';


class BinerAIPage extends StatefulWidget {
  const BinerAIPage({super.key, required this.api});
  final BinerApi api;
  @override State<BinerAIPage> createState() => _BinerAIPageState();
}

class _BinerAIPageState extends State<BinerAIPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _history = <Map<String, dynamic>>[];
  bool _busy = false;

  @override
  void dispose() { _controller.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _ask([String? prompt]) async {
    final question = (prompt ?? _controller.text).trim();
    if (question.isEmpty || _busy) return;
    _controller.clear();
    setState(() { _busy = true; _history.add({'role': 'user', 'text': question}); });
    try {
      final result = await widget.api.askBinerAI(question);
      if (!mounted) return;
      setState(() => _history.add({'role': 'ai', 'data': result}));
    } on ApiException catch (e) {
      if (mounted) setState(() => _history.add({'role': 'error', 'text': e.message}));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
        });
      }
    }
  }

  Widget _glass(Widget child) => BinerSurfaceCard(
    padding: const EdgeInsets.all(15),
    radius: 21,
    accent: BinerPreferences.instance.accent,
    child: child,
  );

  Widget _answer(Map<String, dynamic> data) {
    final profile = data['profile'] is Map ? Map<String, dynamic>.from(data['profile'] as Map) : null;
    final recent = (data['recent_posts'] as List? ?? data['results'] as List? ?? const []).whereType<Map>().toList();
    final limitations = (data['limitations'] as List? ?? const []).map((x) => x.toString()).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(data['answer']?.toString() ?? 'پاسخی دریافت نشد.', style: const TextStyle(height: 1.7)),
      if (profile != null) ...[
        const SizedBox(height: 14),
        _glass(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: Color(0x2239C5FF), child: Icon(Icons.person_rounded, color: BinerPreferences.instance.accent)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile['display_name']?.toString() ?? profile['username']?.toString() ?? 'کاربر', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('@${profile['username'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            if (profile['BlueTick'] == true) Icon(Icons.verified_rounded, color: BinerPreferences.instance.accent),
          ]),
          const Divider(height: 22),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _metric('دنبال‌کننده', profile['followers_count']),
            _metric('پست', profile['posts_count']),
            _metric('نشان آبی', profile['BlueTick'] == true ? 'دارد' : 'ندارد'),
          ]),
          if ((profile['bio']?.toString() ?? '').isNotEmpty) ...[const SizedBox(height: 10), Text(profile['bio'].toString())],
        ])),
      ],
      if (recent.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('پست‌های مرتبط / اخیر', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...recent.take(5).map((p) => _glass(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@${p['username'] ?? ''}', style: TextStyle(color: BinerPreferences.instance.accent, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(p['body']?.toString() ?? '', maxLines: 5, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('♥ ${p['likes_count'] ?? 0}   ↻ ${p['reposts_count'] ?? 0}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]))),
      ],
      if (limitations.isNotEmpty) ...[
        const SizedBox(height: 12),
        _glass(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: BinerPreferences.instance.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(limitations.join('\n'), style: const TextStyle(fontSize: 11, height: 1.6, color: Colors.grey))),
        ])),
      ],
    ]);
  }

  Widget _metric(String label, dynamic value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: BinerPreferences.instance.accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(13)),
    child: Column(children: [Text(value?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [Icon(Icons.auto_awesome_rounded, color: BinerPreferences.instance.accent), SizedBox(width: 9), Text('BinerAI', style: TextStyle(fontWeight: FontWeight.w900))]), actions: [IconButton(tooltip: 'گفت‌وگوی تازه', onPressed: _busy ? null : () => setState(_history.clear), icon: Icon(Icons.add_comment_outlined))]),
    body: Column(children: [
      Expanded(child: _history.isEmpty ? ListView(physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 28),
        Center(child: Container(width: 82, height: 82, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [BinerPreferences.instance.accent, BinerPreferences.instance.accent]), boxShadow: [BoxShadow(color: BinerPreferences.instance.accent.withValues(alpha: .25), blurRadius: 30)]), child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF071426), size: 42))).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 18),
        const Center(child: Text('پرسش کن؛ داده‌ها را شفاف ببین.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
        const Center(child: Text('BinerAI اطلاعات موجود در BinerMention، آمار حساب‌ها و پست‌های عمومی را بررسی می‌کند. این نسخه هنوز جست‌وجوی وب بیرونی ندارد.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.7))),
        const SizedBox(height: 24),
        for (final prompt in ['درباره @hirad990 چه اطلاعاتی در BinerMention ثبت شده؟', 'آخرین پست‌های @hirad990 را نشان بده', 'درباره این موضوع چه پست‌هایی منتشر شده؟'])
          Padding(padding: EdgeInsets.only(bottom: 9), child: OutlinedButton.icon(onPressed: _busy ? null : () => _ask(prompt), icon: Icon(Icons.bolt_rounded), label: Text(prompt), style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.all(14), side: BorderSide(color: BinerPreferences.instance.accent.withValues(alpha: .25))))),
      ]) : ListView(controller: _scroll, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(14, 14, 14, 22), children: [
        for (final item in _history)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: item['role'] == 'user'
            ? Align(alignment: AlignmentDirectional.centerEnd, child: Container(constraints: BoxConstraints(maxWidth: 320), padding: EdgeInsets.all(13), decoration: BoxDecoration(color: BinerPreferences.instance.accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(18)), child: Text(item['text'].toString())))
            : Align(alignment: AlignmentDirectional.centerStart, child: Container(constraints: BoxConstraints(maxWidth: 360), padding: EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: BinerPreferences.instance.accent.withValues(alpha: .18)), borderRadius: BorderRadius.circular(18)), child: item['role'] == 'error' ? Text(item['text'].toString(), style: TextStyle(color: Colors.redAccent)) : _answer(Map<String, dynamic>.from(item['data'] as Map))))),
        if (_busy) Padding(padding: EdgeInsets.all(16), child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BinerPreferences.instance.accent)), SizedBox(width: 10), Text('در حال بررسی داده‌ها…', style: TextStyle(color: Colors.grey))])),
      ])),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, onSubmitted: (_) => _ask(), decoration: InputDecoration(hintText: 'از BinerAI چیزی بپرس…', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _busy ? null : _ask, style: IconButton.styleFrom(backgroundColor: BinerPreferences.instance.accent, foregroundColor: Color(0xFF071426)), icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.arrow_upward_rounded)),
      ]))),
    ]),
  );
}
