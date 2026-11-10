import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue = Color(0xFF54C8FF);
const _violet = Color(0xFF9B8CFF);
const _ink = Color(0xFF080D17);

class CreatorStudioPage extends StatefulWidget {
  const CreatorStudioPage({super.key, this.posts = const []});
  final List<Map<String, dynamic>> posts;
  @override
  State<CreatorStudioPage> createState() => _CreatorStudioPageState();
}

class _CreatorStudioPageState extends State<CreatorStudioPage> {
  List<String> drafts = [];
  List<String> snippets = [];
  List<String> mutedWords = [];
  bool loaded = false;
  final random = math.Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      drafts = prefs.getStringList('creator_drafts_v1') ?? [];
      snippets = prefs.getStringList('creator_snippets_v1') ?? [
        'ممنون از اینکه دیدگاهت را به اشتراک گذاشتی.',
        'این موضوع ارزش بررسی بیشتری دارد.',
        'یک نکتهٔ مهم که نباید فراموش کنیم:'
      ];
      mutedWords = prefs.getStringList('creator_muted_words_v1') ?? [];
      loaded = true;
    });
  }

  Future<void> _persist(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) _toast('کپی شد');
  }

  Future<String?> _editText({String title = 'متن', String initial = '', int maxLength = 5000}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: _blue.withValues(alpha: .25))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: 'اینجا بنویس…',
                filled: true,
                fillColor: Colors.white.withValues(alpha: .045),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ذخیره'))),
            ]),
          ]),
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _draftVault() async {
    while (mounted) {
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: StatefulBuilder(builder: (ctx, refresh) => Column(mainAxisSize: MainAxisSize.min, children: [
            _handle(),
            const SizedBox(height: 12),
            Row(children: [const Expanded(child: Text('گاوصندوق پیش‌نویس‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), _miniAction(Icons.add_rounded, 'پیش‌نویس تازه', () => Navigator.pop(ctx, 'new'))]),
            const SizedBox(height: 12),
            if (drafts.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Text('هنوز پیش‌نویسی ذخیره نکردی.', style: TextStyle(color: Colors.white60))),
            ...List.generate(drafts.length, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .045), borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(drafts[i], maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${drafts[i].length} نویسه', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, 'edit:$i'),
                trailing: IconButton(onPressed: () { drafts.removeAt(i); _persist('creator_drafts_v1', drafts); refresh(() {}); }, icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8293))),
              ),
            )),
          ])),
        )),
      );
      if (!mounted || action == null) break;
      if (action == 'new') {
        final text = await _editText(title: 'پیش‌نویس تازه');
        if (text != null && text.isNotEmpty) { setState(() => drafts.insert(0, text)); await _persist('creator_drafts_v1', drafts); }
      } else if (action.startsWith('edit:')) {
        final i = int.tryParse(action.substring(5));
        if (i != null && i < drafts.length) {
          final text = await _editText(title: 'ویرایش پیش‌نویس', initial: drafts[i]);
          if (text != null) { setState(() { if (text.isEmpty) { drafts.removeAt(i); } else { drafts[i] = text; } }); await _persist('creator_drafts_v1', drafts); }
        }
      }
    }
  }

  Future<void> _hashtagLab() async {
    final controller = TextEditingController();
    String result = '';
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'آزمایشگاه هشتگ',
      'موضوع یا چند کلمه وارد کن؛ هشتگ‌های پیشنهادی به‌صورت محلی ساخته می‌شوند.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, onChanged: (_) => refresh(() {}), decoration: const InputDecoration(hintText: 'مثلاً برنامه‌نویسی، تکنولوژی، هنر')),
        const SizedBox(height: 12),
        if (result.isNotEmpty) SelectableText(result, style: const TextStyle(color: _blue, height: 1.8, fontWeight: FontWeight.w700)),
        _primary('ساخت هشتگ', () {
          final words = controller.text.split(RegExp(r'[^\p{L}\p{N}_]+', unicode: true)).where((e) => e.length > 1).toSet().take(8);
          result = words.map((e) => '#${e.replaceAll(RegExp(r'[^\p{L}\p{N}_]', unicode: true), '')}').join(' ');
          refresh(() {});
        }),
        if (result.isNotEmpty) _secondary('کپی هشتگ‌ها', () => _copy(result)),
      ]),
    )));
    controller.dispose();
  }

  Future<void> _formatter() async {
    final controller = TextEditingController();
    String output = '';
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'کارگاه ویرایش متن',
      'متن را مرتب کن و نسخهٔ تمیزشده را کپی کن.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'متن خودت را وارد کن…')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip('پاک‌سازی فاصله‌ها', () => output = controller.text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim(), () => refresh(() {})),
          _chip('فهرست‌سازی', () => output = controller.text.split('\n').where((e) => e.trim().isNotEmpty).map((e) => '• ${e.trim()}').join('\n'), () => refresh(() {})),
          _chip('نقل‌قول', () => output = controller.text.split('\n').map((e) => '“${e.trim()}”').join('\n'), () => refresh(() {})),
        ]),
        if (output.isNotEmpty) ...[const SizedBox(height: 12), SelectableText(output, style: const TextStyle(height: 1.6)) , _secondary('کپی خروجی', () => _copy(output))],
      ]),
    )));
    controller.dispose();
  }

  Future<void> _snippetLibrary() async {
    final value = await showModalBottomSheet<String>(context: context, backgroundColor: Theme.of(context).colorScheme.surfaceContainer, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (ctx) => SafeArea(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(), const SizedBox(height: 12),
        const Align(alignment: Alignment.centerRight, child: Text('کتابخانهٔ پاسخ‌های آماده', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
        const SizedBox(height: 10),
        ...List.generate(snippets.length, (i) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(snippets[i], maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: IconButton(onPressed: () => Navigator.pop(ctx, 'copy:$i'), icon: const Icon(Icons.copy_rounded, color: _blue)),
          onTap: () => Navigator.pop(ctx, 'copy:$i'),
        )),
        _primary('افزودن پاسخ آماده', () => Navigator.pop(ctx, 'new')),
      ]),
    )));
    if (value == 'new') {
      final text = await _editText(title: 'پاسخ آمادهٔ جدید');
      if (text != null && text.isNotEmpty) { setState(() => snippets.add(text)); await _persist('creator_snippets_v1', snippets); }
    } else if (value != null && value.startsWith('copy:')) {
      final i = int.tryParse(value.substring(5));
      if (i != null && i < snippets.length) await _copy(snippets[i]);
    }
  }

  Future<void> _muteWords() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'فیلتر واژه‌های دلخواه',
      'واژه‌هایی که نمی‌خواهی در فید ببینی ذخیره کن. این فهرست آمادهٔ اتصال به فیلتر فید است.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, decoration: const InputDecoration(hintText: 'یک واژه یا عبارت')),
        const SizedBox(height: 8),
        _primary('افزودن واژه', () { final word = controller.text.trim(); if (word.isNotEmpty && !mutedWords.contains(word)) { setState(() => mutedWords.add(word)); _persist('creator_muted_words_v1', mutedWords); controller.clear(); refresh(() {}); } }),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: mutedWords.map((word) => InputChip(label: Text(word), onDeleted: () { setState(() => mutedWords.remove(word)); _persist('creator_muted_words_v1', mutedWords); refresh(() {}); })).toList()),
      ]),
    )));
    controller.dispose();
  }

  Future<void> _readingMode() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(context: context, builder: (ctx) => _toolDialog(
      'حالت مطالعهٔ متمرکز',
      'متن یک پست را اینجا قرار بده تا بدون شلوغی و با خوانایی بیشتر نمایش داده شود.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'متن پست…')),
        _primary('شروع مطالعه', () => Navigator.pop(ctx, controller.text.trim())),
      ]),
    ));
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    await showDialog<void>(context: context, builder: (ctx) => Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: _blue.withValues(alpha: .25))),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.menu_book_rounded, color: _blue, size: 30),
        const SizedBox(height: 16),
        SelectableText(text, textAlign: TextAlign.start, style: const TextStyle(fontSize: 19, height: 1.9, letterSpacing: .1)),
        const SizedBox(height: 16),
        Text('${text.split(RegExp(r'\s+')).length} واژه · حدود ${(text.split(RegExp(r'\s+')).length / 180).ceil()} دقیقه مطالعه', style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ])),
    ));
  }

  Future<void> _bioWorkshop() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'استودیوی بیوگرافی',
      'بیوی کوتاه پروفایلت را بنویس، پیش‌نمایش بگیر و کپی کن.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, maxLength: 160, minLines: 2, maxLines: 4, onChanged: (_) => refresh(() {}), decoration: const InputDecoration(hintText: 'علاقه‌مندی‌ها، تخصص‌ها و لینک‌ها…')),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(backgroundColor: Color(0xFF18314B), child: Icon(Icons.person_rounded, color: _blue)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('پیش‌نمایش پروفایل', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(controller.text.isEmpty ? 'بیوی تو اینجا نمایش داده می‌شود.' : controller.text, style: const TextStyle(color: Colors.white70, height: 1.5))])),
        ])),
        _secondary('کپی بیو', () => _copy(controller.text.trim())),
      ]),
    )));
    controller.dispose();
  }

  Future<void> _ideaGenerator() async {
    const ideas = [
      'یک ابزار دیجیتال که زندگی روزمره را ساده‌تر می‌کند معرفی کن.',
      'از یک اشتباه جالب که چیز مهمی به تو یاد داد بنویس.',
      'یک باور رایج در دنیای فناوری را به چالش بکش.',
      'سه منبع رایگان برای یادگیری یک مهارت معرفی کن.',
      'اگر می‌توانستی یک قابلیت به شبکه‌های اجتماعی اضافه کنی، چه بود؟',
      'یک پروژهٔ کوچک را از ایده تا نتیجه روایت کن.',
      'یک کتاب یا فیلم که نگاهت را تغییر داد معرفی کن.',
      'یک سؤال بپرس که باعث شروع یک گفت‌وگوی واقعی شود.',
    ];
    setState(() => _idea = ideas[random.nextInt(ideas.length)]);
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'مولد ایدهٔ پست',
      'برای شروع نوشتن، یک جرقهٔ تازه بگیر.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Text(_idea, style: const TextStyle(fontSize: 17, height: 1.6, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        _primary('ایدهٔ بعدی', () { setState(() => _idea = ideas[random.nextInt(ideas.length)]); refresh(() {}); }),
        _secondary('کپی ایده', () => _copy(_idea)),
      ]),
    )));
  }
  String _idea = 'برای شروع، یک ایده انتخاب کن.';

  Future<void> _threadPlanner() async {
    final controller = TextEditingController();
    List<String> parts = [];
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => _toolDialog(
      'برنامه‌ریز رشته‌پست',
      'یک متن بلند را به بخش‌های حداکثر ۲۸۰ نویسه‌ای تقسیم کن.',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, minLines: 3, maxLines: 6, maxLength: 10000, decoration: const InputDecoration(hintText: 'متن کامل رشته‌پست…')),
        _primary('تقسیم متن', () {
          final words = controller.text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
          parts = [];
          var current = '';
          for (final word in words) {
            if ((current.isEmpty ? word : '$current $word').length > 270 && current.isNotEmpty) {
              parts.add(current); current = word;
            } else { current = current.isEmpty ? word : '$current $word'; }
          }
          if (current.isNotEmpty) parts.add(current);
          refresh(() {});
        }),
        if (parts.isNotEmpty) ...[
          Text('${parts.length} بخش آماده شد', style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
          SizedBox(height: 220, child: ListView.builder(itemCount: parts.length, itemBuilder: (_, i) => Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('بخش ${i + 1} · ${parts[i].length}/280', style: const TextStyle(color: _blue, fontSize: 11)), const SizedBox(height: 5), Text(parts[i])])))),
          _secondary('کپی کل رشته‌پست', () => _copy(parts.asMap().entries.map((e) => '${e.value}\n(${e.key + 1}/${parts.length})').join('\n\n'))),
        ],
      ]),
    )));
    controller.dispose();
  }

  Widget _handle() => Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))));
  Widget _miniAction(IconData icon, String label, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: _blue.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: _blue, size: 17), const SizedBox(width: 5), Text(label, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w800))])));
  Widget _primary(String label, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(top: 12), child: SizedBox(height: 46, child: FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: _ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)))));
  Widget _secondary(String label, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: _blue, side: BorderSide(color: _blue.withValues(alpha: .35)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label)));
  Widget _chip(String label, VoidCallback onTap, VoidCallback refresh) => ActionChip(label: Text(label, style: const TextStyle(fontSize: 11)), onPressed: () { onTap(); refresh(); }, backgroundColor: _blue.withValues(alpha: .10), side: BorderSide(color: _blue.withValues(alpha: .2)));
  Widget _toolDialog(String title, String subtitle, Widget child) => Dialog(
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: _blue.withValues(alpha: .24))),
    child: Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
      const SizedBox(height: 16), child,
      Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))),
    ]))),
  );

  List<_StudioTool> get _tools => [
    _StudioTool('گاوصندوق پیش‌نویس‌ها', 'نوشتن را ذخیره کن و بعداً ادامه بده', Icons.inventory_2_outlined, _violet, _draftVault),
    _StudioTool('آزمایشگاه هشتگ', 'ساخت هشتگ از موضوع و کلیدواژه', Icons.tag_rounded, _blue, _hashtagLab),
    _StudioTool('کارگاه ویرایش متن', 'پاک‌سازی فاصله، نقل‌قول و فهرست‌سازی', Icons.auto_fix_high_rounded, const Color(0xFF66D6B2), _formatter),
    _StudioTool('کتابخانهٔ پاسخ آماده', 'عبارت‌های پرکاربردت را سریع کپی کن', Icons.library_books_outlined, const Color(0xFFFFC46B), _snippetLibrary),
    _StudioTool('فیلتر واژه‌ها', 'فهرست واژه‌هایی که نمی‌خواهی ببینی', Icons.filter_alt_outlined, const Color(0xFFFF8293), _muteWords),
    _StudioTool('حالت مطالعه', 'خواندن متن در محیط خلوت و خوانا', Icons.menu_book_rounded, _blue, _readingMode),
    _StudioTool('استودیوی بیوگرافی', 'ساخت و پیش‌نمایش بیوی پروفایل', Icons.badge_outlined, _violet, _bioWorkshop),
    _StudioTool('مولد ایدهٔ پست', 'پیشنهاد موضوع برای انتشار بعدی', Icons.lightbulb_outline_rounded, const Color(0xFFFFC46B), _ideaGenerator),
    _StudioTool('تحلیل‌گر متن', 'آمار نویسه، واژه، هشتگ و زمان مطالعه', Icons.query_stats_rounded, const Color(0xFF66D6B2), _textAnalyzer),
    _StudioTool('برنامه‌ریز رشته‌پست', 'تقسیم متن بلند به پست‌های کوتاه', Icons.view_stream_outlined, _blue, _threadPlanner),
  ];

  Future<void> _textAnalyzer() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
      final text = controller.text;
      final words = text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
      final hashtags = RegExp(r'#[\p{L}\p{N}_]+', unicode: true).allMatches(text).length;
      final mentions = RegExp(r'@[A-Za-z0-9_]+').allMatches(text).length;
      return _toolDialog('تحلیل‌گر متن', 'آمار زندهٔ نوشته؛ همه‌چیز روی خود دستگاه محاسبه می‌شود.', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: controller, minLines: 3, maxLines: 6, onChanged: (_) => refresh(() {}), decoration: const InputDecoration(hintText: 'متنت را وارد کن…')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _metric('نویسه', '${text.length}'), _metric('واژه', '${words.length}'), _metric('هشتگ', '$hashtags'), _metric('منشن', '$mentions'), _metric('مطالعه', '${(words.length / 180).ceil()} دقیقه'),
        ]),
      ]));
    }));
    controller.dispose();
  }

  Widget _metric(String label, String value) => Container(width: 94, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(value, style: const TextStyle(fontSize: 18, color: _blue, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60))]));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: Theme.of(context).colorScheme.surface,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Creator Studio'), leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded))),
      body: !loaded ? const Center(child: CircularProgressIndicator(color: _blue)) : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 18), child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(26), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.bolt_rounded, color: _blue), SizedBox(width: 8), Text('BINER / CREATOR TOOLS', style: TextStyle(fontSize: 10, letterSpacing: 1.8, color: Colors.white70, fontWeight: FontWeight.w900))]),
              const SizedBox(height: 12),
              const Text('ایده‌ات را به محتوا تبدیل کن.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, height: 1.3)),
              const SizedBox(height: 6),
              Text('۱۰ ابزار کاربردی برای نوشتن، مدیریت متن و ساخت محتوای بهتر.', style: TextStyle(color: Colors.white.withValues(alpha: .68), fontSize: 12, height: 1.6)),
              const SizedBox(height: 16),
              Row(children: [_metric('پیش‌نویس', '${drafts.length}'), const SizedBox(width: 8), _metric('عبارت آماده', '${snippets.length}'), const SizedBox(width: 8), _metric('فیلتر', '${mutedWords.length}')]),
            ]),
          ))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 30), sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final tool = _tools[index];
              return InkWell(
                onTap: tool.open,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xE6101722) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tool.color.withValues(alpha: .23)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .12 : .035), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: tool.color.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(tool.icon, color: tool.color)),
                    const Spacer(),
                    Text(tool.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(tool.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58))),
                  ]),
                ),
              );
            }, childCount: _tools.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .98),
          )),
        ],
      ),
    );
  }
}

class _StudioTool {
  const _StudioTool(this.title, this.subtitle, this.icon, this.color, this.open);
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback open;
}
