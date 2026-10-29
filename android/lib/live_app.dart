import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_client.dart';
import 'ui_kit.dart';
import 'profile_page.dart';
import 'package:image_picker/image_picker.dart';

const cBg = Color(0xFF050812), cPanel = Color(0xCC101B2C), cLine = Color(0x5537BFFF), cBlue = Color(0xFF39C5FF), cMuted = Color(0xFF91A6C3), cGlass = Color(0x99121F32);

class BinerLiveApp extends StatefulWidget {
  const BinerLiveApp({super.key});
  @override State<BinerLiveApp> createState() => _BinerLiveAppState();
}
class _BinerLiveAppState extends State<BinerLiveApp> {
  final api = BinerApi();
  bool ready = false, loggedIn = false;
  ThemeMode themeMode = ThemeMode.dark;
  void toggleTheme() {
    final next = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => themeMode = next);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('biner_theme_dark', next == ThemeMode.dark));
  }
  @override void initState() { super.initState(); init(); }
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = prefs.getBool('biner_theme_dark') == false ? ThemeMode.light : ThemeMode.dark;
    await api.restoreSession();
    if (api.isAuthenticated) { try { await api.me(); loggedIn = true; } on ApiException { loggedIn = false; } }
    if (mounted) setState(() => ready = true);
  }
  void signedIn() => setState(() => loggedIn = true);
  Future<void> logout() async { await api.logout(); if (mounted) setState(() => loggedIn = false); }
  @override void dispose() { api.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'BinerMention',
    debugShowCheckedModeBanner: false,
    theme: buildBinerTheme(Brightness.light),
    darkTheme: buildBinerTheme(Brightness.dark),
    themeMode: themeMode,
    builder: (context, child) => BinerBackdrop(child: child ?? const SizedBox.shrink()),
    home: AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: !ready
          ? const Scaffold(key: ValueKey('boot'), body: Center(child: CircularProgressIndicator(color: cBlue)))
          : loggedIn
              ? LiveHome(key: const ValueKey('home'), api: api, logout: logout, onToggleTheme: toggleTheme, isDark: themeMode == ThemeMode.dark)
              : LiveAuth(key: const ValueKey('auth'), api: api, onDone: signedIn),
    ),
  );
}

class LiveAuth extends StatefulWidget {
  const LiveAuth({super.key, required this.api, required this.onDone});
  final BinerApi api; final VoidCallback onDone;
  @override State<LiveAuth> createState() => _LiveAuthState();
}
class _LiveAuthState extends State<LiveAuth> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(), email = TextEditingController(), password = TextEditingController(), displayName = TextEditingController();
  bool register = false, busy = false, hide = true; String? error;
  @override void dispose() { username.dispose(); email.dispose(); password.dispose(); displayName.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      if (register) {
        await widget.api.register(username: username.text.trim(), email: email.text.trim(), password: password.text, displayName: displayName.text.trim().isEmpty ? username.text.trim() : displayName.text.trim());
      } else { await widget.api.login(username.text.trim(), password.text); }
      widget.onDone();
    } on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440), child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: ClipPath(clipper: BinerHeroClipper(), child: Container(width: 78, height: 78, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [cBlue, Color(0xFF2554E8)])), child: const Icon(Icons.bolt, size: 48)))),
      const SizedBox(height: 18), const Center(child: Brand()),
      const SizedBox(height: 8), Text(register ? 'به جامعه‌ات بپیوند.' : 'صدای تو. دنیای تو.', textAlign: TextAlign.center, style: const TextStyle(color: cMuted)),
      const SizedBox(height: 30),
      if (register) ...[TextFormField(controller: displayName, decoration: const InputDecoration(labelText: 'نام نمایشی'), validator: (v) => v != null && v.length > 80 ? 'حداکثر ۸۰ نویسه.' : null), const SizedBox(height: 12)],
      TextFormField(controller: username, autocorrect: false, decoration: InputDecoration(labelText: register ? 'نام کاربری' : 'نام کاربری یا ایمیل'), validator: (v) {
        if (v == null || v.trim().isEmpty) return 'این فیلد الزامی است.';
        if (register && !RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(v.trim())) return 'نام کاربری ۳ تا ۲۴ نویسه باشد.';
        return null;
      }),
      if (register) ...[const SizedBox(height: 12), TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل'), validator: (v) => v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'ایمیل معتبر وارد کن.' : null)],
      const SizedBox(height: 12),
      TextFormField(controller: password, obscureText: hide, decoration: InputDecoration(labelText: 'رمز عبور', suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility : Icons.visibility_off))), validator: (v) => v == null || v.isEmpty ? 'رمز عبور الزامی است.' : register && v.length < 10 ? 'حداقل ۱۰ نویسه وارد کن.' : null, onFieldSubmitted: (_) => submit()),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.redAccent))],
      const SizedBox(height: 18), SizedBox(height: 50, child: FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(register ? 'ساخت حساب' : 'ورود'))),
      TextButton(onPressed: busy ? null : () => setState(() { register = !register; error = null; }), child: Text(register ? 'حساب داری؟ وارد شو' : 'حساب نداری؟ ثبت‌نام کن')),
    ])),
  )))));
}

class LiveHome extends StatefulWidget {
  const LiveHome({super.key, required this.api, required this.logout, required this.onToggleTheme, required this.isDark});
  final BinerApi api; final Future<void> Function() logout;
  final VoidCallback onToggleTheme;
  final bool isDark;
  @override State<LiveHome> createState() => _LiveHomeState();
}
class _LiveHomeState extends State<LiveHome> {
  int tab = 0; bool loading = true, posting = false, followingFeed = false; String? error;
  final posts = <Map<String, dynamic>>[]; Map<String, dynamic>? me;
  final Set<String> _postActionsInFlight = <String>{};
  @override void initState() { super.initState(); refresh(); loadProfile(); }
  Future<void> loadProfile() async { try { final u = await widget.api.me(); if (mounted) setState(() => me = u); } on ApiException catch (e) { if (mounted) setState(() => error = e.message); } }
  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try { final data = await widget.api.posts(following: followingFeed); if (mounted) setState(() { posts..clear()..addAll(data); }); }
    on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> openUserProfile(String username) async {
    final normalized = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => UserProfilePage(api: widget.api, username: normalized),
    ));
  }

  Future<void> openHashtag(String hashtag) async {
    final query = hashtag.trim().replaceFirst(RegExp(r'^#'), '');
    if (query.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * .78,
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xF20B1422) : const Color(0xF7FFFFFF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: cLine),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Icon(Icons.tag_rounded, color: cBlue),
              const SizedBox(width: 8),
              Expanded(child: Text('#$query', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.api.searchPosts(query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
                if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(snapshot.error.toString(), textAlign: TextAlign.center)));
                final found = snapshot.data ?? const <Map<String, dynamic>>[];
                if (found.isEmpty) return const Center(child: Text('پستی با این هشتگ پیدا نشد.'));
                return ListView.builder(itemCount: found.length, itemBuilder: (_, i) => card(found[i]));
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget richPostBody(String body) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'#[A-Za-z0-9_\u0600-\u06FF]{2,40}|@[A-Za-z0-9_]{3,24}');
    var cursor = 0;
    for (final match in pattern.allMatches(body)) {
      if (match.start > cursor) spans.add(TextSpan(text: body.substring(cursor, match.start)));
      final token = match.group(0)!;
      final isTag = token.startsWith('#');
      final value = token.substring(1);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => isTag ? openHashtag(value) : openUserProfile(value),
          child: Text(token, style: TextStyle(color: isTag ? const Color(0xFF35A7F5) : const Color(0xFF9B8CFF), fontWeight: FontWeight.w700)),
        ),
      ));
      cursor = match.end;
    }
    if (cursor < body.length) spans.add(TextSpan(text: body.substring(cursor)));
    return RichText(text: TextSpan(style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.48, letterSpacing: .05), children: spans));
  }
  Future<void> compose({int? replyToId}) async {
    final controller = TextEditingController();
    XFile? attachment;
    void insertToken(String token) {
      final current = controller.value;
      final selection = current.selection;
      final start = selection.isValid ? selection.start : current.text.length;
      final end = selection.isValid ? selection.end : current.text.length;
      final text = current.text.replaceRange(start, end, token);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: start + token.length),
      );
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sheetSetState) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(replyToId == null ? 'پست جدید' : 'پاسخ به پست #$replyToId',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 5, maxLength: 280,
                  decoration: const InputDecoration(hintText: 'چه خبر؟  #هشتگ  @منشن', border: InputBorder.none)),
              if (attachment != null)
                ListTile(leading: const Icon(Icons.image, color: cBlue), title: Text(attachment!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => sheetSetState(() => attachment = null))),
              Row(children: [
                IconButton(tooltip: 'افزودن هشتگ', onPressed: () => insertToken('#'), icon: const Icon(Icons.tag_rounded, color: cBlue)),
                IconButton(tooltip: 'منشن کردن کاربر', onPressed: () => insertToken('@'), icon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF9B8CFF))),
                IconButton(
                  tooltip: 'افزودن تصویر',
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 86, maxWidth: 2048);
                    if (picked != null) sheetSetState(() => attachment = picked);
                  },
                  icon: const Icon(Icons.image_outlined, color: cBlue),
                ),
                const Spacer(),
                FilledButton(onPressed: () => Navigator.pop(ctx, {'text': controller.text.trim(), 'attachment': attachment}),
                    child: const Text('انتشار')),
              ]),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final text = (result['text'] as String? ?? '').trim();
    final file = result['attachment'] as XFile?;
    if (text.isEmpty && file == null) return;
    setState(() => posting = true);
    try {
      int? mediaId;
      if (file != null) {
        final media = await widget.api.uploadMedia(file);
        mediaId = int.tryParse(media['id'].toString());
      }
      final item = await widget.api.createPost(text, mediaId: mediaId, replyToId: replyToId);
      if (mounted) setState(() => posts.insert(0, item));
      if (replyToId != null && mounted) toast('پاسخ منتشر شد.');
    } on ApiException catch (e) {
      if (mounted) toast(e.message);
    } finally {
      if (mounted) setState(() => posting = false);
    }
  }

  Future<void> editPost(Map<String, dynamic> post) async {
    final controller = TextEditingController(text: value(post, 'body'));
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش پست'),
        content: TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 6, maxLength: 280),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ذخیره')),
        ],
      ),
    );
    controller.dispose();
    if (text == null || !mounted) return;
    try {
      final updated = await widget.api.updatePost(int.parse(value(post, 'id')), text);
      if (mounted) setState(() {
        final index = posts.indexWhere((item) => value(item, 'id') == value(post, 'id'));
        if (index >= 0) posts[index] = updated;
      });
      if (mounted) toast('پست ویرایش شد.');
    } on ApiException catch (e) {
      if (mounted) toast(e.message);
    }
  }

  Future<void> deletePost(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پست؟'),
        content: const Text('این کار پست را از فید حذف می‌کند.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.api.deletePost(id);
      if (mounted) setState(() => posts.removeWhere((p) => value(p, 'id') == id.toString()));
      if (mounted) toast('پست حذف شد.');
    } on ApiException catch (e) {
      if (mounted) toast(e.message);
    }
  }

  Future<void> toggle(Map<String, dynamic> p, String actionName) async {
    final flag = actionName == 'like' ? 'liked' : 'reposted', count = actionName == 'like' ? 'likes_count' : 'reposts_count';
    final id = int.tryParse(p['id'].toString()); if (id == null) return;
    final lockKey = '$id:$actionName';
    if (_postActionsInFlight.contains(lockKey)) return;
    _postActionsInFlight.add(lockKey);
    final oldFlag = p[flag] == true, oldCount = int.tryParse((p[count] ?? 0).toString()) ?? 0;
    setState(() { p[flag] = !oldFlag; p[count] = oldCount + (oldFlag ? -1 : 1); });
    try {
      await widget.api.togglePostAction(id, actionName, !oldFlag);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { p[flag] = oldFlag; p[count] = oldCount; });
      toast(e.message);
    } finally {
      _postActionsInFlight.remove(lockKey);
    }
  }
  String value(Map<String, dynamic> m, String k, [String fallback = '']) => m[k]?.toString() ?? fallback;
  String fmt(dynamic raw) { final n = int.tryParse(raw.toString()) ?? 0; if (n >= 1000) return (n / 1000).toStringAsFixed(1) + 'K'; return n.toString(); }
  Widget avatar(String n, [Map<String, dynamic>? user, double radius = 22]) {
    final url = user?['avatar_url']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [cBlue, Color(0xFF7A5CFF)]), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: .16), blurRadius: 14)]),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF17334F) : const Color(0xFFE6EFFB),
        backgroundImage: url.startsWith('https://') ? NetworkImage(url) : null,
        child: url.startsWith('https://') ? null : Text(n.isEmpty ? '?' : n[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
  Widget blueTick(Map<String, dynamic> user) {
    final raw = user['BlueTick'];
    final normalized = raw?.toString().trim().toLowerCase();
    final verified = raw == true || raw == 1 || normalized == 'true' || normalized == '1' || normalized == 'yes';
    return verified ? const Padding(padding: EdgeInsets.only(left: 4), child: Tooltip(message: 'حساب تأییدشده', child: Icon(Icons.verified_rounded, color: Color(0xFF1D9BF0), size: 16))) : const SizedBox.shrink();
  }
  Future<void> showReplies(Map<String, dynamic> post) async {
    final id = int.tryParse(value(post, 'id'));
    if (id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * .76,
        decoration: BoxDecoration(color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xF20B1422) : const Color(0xF7FFFFFF), borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), border: Border.all(color: cLine)),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .5), borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), child: Row(children: [
            const Expanded(child: Text('گفت‌وگوی پست', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
            Text(fmt(post['replies_count'] ?? 0) + ' پاسخ', style: const TextStyle(color: cMuted)),
          ])),
          Container(margin: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? cGlass : const Color(0xEFFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: cLine)), child: card(post)),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.api.posts(limit: 50, replyToId: id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
                if (snap.hasError) return Center(child: Text(snap.error.toString(), textAlign: TextAlign.center));
                final replies = snap.data ?? [];
                if (replies.isEmpty) return const Center(child: Text('هنوز پاسخی نیست؛ اولین نفر باش.', style: TextStyle(color: cMuted)));
                return ListView.builder(itemCount: replies.length, itemBuilder: (_, i) => card(replies[i]));
              },
            ),
          ),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () { Navigator.pop(ctx); compose(replyToId: id); },
              icon: const Icon(Icons.reply_rounded), label: const Text('نوشتن پاسخ'),
            )),
          )),
        ]),
      ),
    );
  }

  Widget card(Map<String, dynamic> p) {
    final name = value(p, 'display_name', value(p, 'username', 'کاربر'));
    final body = value(p, 'body');
    final liked = p['liked'] == true, reposted = p['reposted'] == true;
    return Container(padding: const EdgeInsets.fromLTRB(15, 15, 15, 11), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xCC101827) : const Color(0xF7FFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0x4439C5FF) : const Color(0x223D6592)), boxShadow: [BoxShadow(color: Theme.of(context).brightness == Brightness.dark ? const Color(0x16000000) : const Color(0x0D27476A), blurRadius: 22, offset: const Offset(0, 7))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: () => openUserProfile(value(p, 'username')), child: avatar(name, p, 21)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 3, children: [
            GestureDetector(onTap: () => openUserProfile(value(p, 'username')), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
            blueTick(p),
            GestureDetector(onTap: () => openUserProfile(value(p, 'username')), child: Text('@' + value(p, 'username', 'user'), style: const TextStyle(color: Color(0xFF8496AC), fontSize: 12))),
          ])),
          if (value(p, 'user_id') == value(me ?? {}, 'id'))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: cMuted),
              onSelected: (action) {
                final id = int.tryParse(value(p, 'id'));
                if (id == null) return;
                if (action == 'edit') editPost(p);
                if (action == 'delete') deletePost(id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('ویرایش پست')),
                PopupMenuItem(value: 'delete', child: Text('حذف پست')),
              ],
            ),
        ]),
        if (body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8, right: 2), child: richPostBody(body)),
        if (value(p, 'media_url').startsWith('https://')) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(value(p, 'media_url'), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 7)), onPressed: () => showReplies(p), icon: const Icon(Icons.chat_bubble_outline, size: 17), label: Text(fmt(p['replies_count'] ?? 0))),
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: reposted ? const Color(0xFF00BA7C) : cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 7)), onPressed: () => toggle(p, 'repost'), icon: const Icon(Icons.repeat, size: 17), label: Text(fmt(p['reposts_count'] ?? 0))),
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: liked ? const Color(0xFFF91880) : cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 7)), onPressed: () => toggle(p, 'like'), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 17), label: Text(fmt(p['likes_count'] ?? 0))),
        ]),
      ])),
    ])).animate().fadeIn(duration: 240.ms).slideY(begin: .035, duration: 240.ms, curve: Curves.easeOutCubic);
  }
  Widget home() => Column(
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
        const Brand(), const Spacer(),
        Container(decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? cGlass : const Color(0xEFFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: cLine)), child: IconButton(onPressed: searchUser, icon: const Icon(Icons.search_rounded, color: cBlue), tooltip: 'جست‌وجوی کاربر')),
        const SizedBox(width: 4),
        IconButton(
          tooltip: widget.isDark ? 'حالت روشن' : 'حالت تیره',
          onPressed: widget.onToggleTheme,
          icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: cBlue),
        ),
        const SizedBox(width: 4),
        Hero(tag: 'biner-profile-avatar', child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [cBlue, Color(0xFF725BFF)])), child: CircleAvatar(radius: 17, backgroundColor: Theme.of(context).colorScheme.surface, backgroundImage: (me?['avatar_url']?.toString().startsWith('https://') ?? false) ? NetworkImage(me!['avatar_url'].toString()) : null, child: (me?['avatar_url']?.toString().startsWith('https://') ?? false) ? null : const Icon(Icons.person, size: 18)))),
      ])),
      Row(children: [
        Expanded(child: InkWell(
          onTap: () { if (followingFeed) { setState(() => followingFeed = false); refresh(); } },
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('برای تو', style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? cMuted : Theme.of(context).colorScheme.onSurface))),
            Container(height: 3, width: 82, decoration: BoxDecoration(color: followingFeed ? Colors.transparent : cBlue, borderRadius: BorderRadius.circular(3))),
          ]),
        )),
        Expanded(child: InkWell(
          onTap: () { if (!followingFeed) { setState(() => followingFeed = true); refresh(); } },
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('دنبال‌شونده‌ها', style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? Theme.of(context).colorScheme.onSurface : cMuted))),
            Container(height: 3, width: 112, decoration: BoxDecoration(color: followingFeed ? cBlue : Colors.transparent, borderRadius: BorderRadius.circular(3))),
          ]),
        )),
      ]),
      const Divider(height: 1, color: cLine),
      Expanded(child: feedBody()),
    ],
  );

  Widget feedBody() {
    if (loading && posts.isEmpty) {
      return const SingleChildScrollView(
        child: Column(children: [BinerSkeleton(), BinerSkeleton(), BinerSkeleton(), BinerSkeleton()]),
      );
    }
    if (error != null && posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: refresh, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      );
    }
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(children: const [
          SizedBox(height: 100),
          Center(child: Text('هنوز پستی وجود ندارد.')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (_, i) => card(posts[i]),
      ),
    );
  }

  Widget notifications() => FutureBuilder<List<Map<String, dynamic>>>(future: widget.api.notifications(), builder: (context, s) {
    if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
    if (s.hasError) return Center(child: Text(s.error.toString()));
    final items = s.data ?? [];
    return ListView(children: [const Padding(padding: EdgeInsets.all(18), child: Text('اعلان‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      if (items.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('اعلان تازه‌ای نداری.'))),
      ...items.map((n) { final kind = value(n, 'type'); final labels = {'mention': 'در یک پست منشن‌ات کرد', 'follow': 'دنبال‌ات کرد', 'like': 'پستت را پسندید', 'repost': 'پستت را بازنشر کرد', 'reply': 'به پستت پاسخ داد', 'message': 'پیام فرستاد'}; return ListTile(leading: avatar(value(n, 'actor_display_name', value(n, 'actor_username', 'U'))), title: Text(value(n, 'actor_display_name', value(n, 'actor_username', 'کاربر')) + ' • ' + (labels[kind] ?? 'تعامل جدید')), subtitle: Text(value(n, 'created_at'), style: const TextStyle(color: cMuted))); }),
    ]);
  });
  Future<void> startConversation() async {
    final controller = TextEditingController();
    final username = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('پیام جدید'),
      content: TextField(controller: controller, autocorrect: false, decoration: const InputDecoration(labelText: 'نام کاربری گیرنده')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ادامه')),
      ],
    ));
    controller.dispose();
    if (username == null || username.isEmpty || !mounted) return;
    try {
      final currentUser = me ?? await widget.api.me();
      final user = await widget.api.userByUsername(username.replaceFirst('@', ''));
      final id = int.parse(user['id'].toString());
      final conversationId = await widget.api.createConversation(id);
      if (!mounted) return;
      setState(() => me = currentUser);
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatPage(
        api: widget.api,
        conversationId: conversationId,
        currentUserId: int.parse(currentUser['id'].toString()),
        title: user['display_name']?.toString() ?? user['username']?.toString() ?? username,
      )));
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) toast(e.message);
    } on FormatException {
      if (mounted) toast('پاسخ سرور معتبر نیست.');
    }
  }

  Widget conversations() => FutureBuilder<List<Map<String, dynamic>>>(
    future: widget.api.conversations(),
    builder: (context, s) {
      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
      if (s.hasError) return Center(child: Text(s.error.toString(), textAlign: TextAlign.center));
      final items = s.data ?? [];
      return ListView(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 8, 12), child: Row(children: [
          const Expanded(child: Text('پیام‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          IconButton(onPressed: startConversation, icon: const Icon(Icons.edit_square, color: cBlue), tooltip: 'پیام جدید'),
        ])),
        if (items.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('هنوز گفت‌وگویی نداری. برای شروع روی پیام جدید بزن.'))),
        ...items.map((c) => ListTile(
          leading: avatar('M'),
          title: Text('گفت‌وگو #' + value(c, 'id')),
          subtitle: Text(value(c, 'last_message', 'گفت‌وگوی جدید'), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right, color: cMuted),
          onTap: () async {
            final id = int.tryParse(value(c, 'id'));
            if (id == null) return;
            try {
              final currentUser = me ?? await widget.api.me();
              if (!mounted) return;
              setState(() => me = currentUser);
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatPage(
                api: widget.api,
                conversationId: id,
                currentUserId: int.parse(currentUser['id'].toString()),
                title: 'گفت‌وگو #' + id.toString(),
              )));
            } on ApiException catch (e) {
              if (mounted) toast(e.message);
            }
            if (mounted) setState(() {});
          },
        )),
      ]);
    },
  );

  Future<void> searchUser() async {
    final controller = TextEditingController();
    Future<List<Map<String, dynamic>>>? results;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sheetSetState) => Container(
          height: MediaQuery.of(ctx).size.height * .78,
          padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: const Color(0xF20B1422),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: cLine),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .5), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            const Text('کشف آدم‌های جدید', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              onChanged: (q) => sheetSetState(() {
                results = q.trim().replaceFirst(RegExp(r'^@'), '').length >= 2 ? widget.api.searchUsers(q.trim()) : null;
              }),
              decoration: InputDecoration(
                hintText: 'نام کاربری یا نام نمایشی…',
                prefixIcon: const Icon(Icons.search_rounded, color: cBlue),
                filled: true, fillColor: cGlass,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: cLine)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: cLine)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results == null
                ? const Center(child: Text('برای شروع، حداقل ۲ حرف بنویس.', style: TextStyle(color: cMuted)))
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: results,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
                      if (snap.hasError) return Center(child: Text(snap.error.toString(), textAlign: TextAlign.center));
                      final users = snap.data ?? [];
                      if (users.isEmpty) return const Center(child: Text('کاربری پیدا نشد.'));
                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(color: cLine, height: 1),
                        itemBuilder: (_, i) {
                          final user = users[i];
                          final display = value(user, 'display_name', value(user, 'username', 'کاربر'));
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            leading: avatar(display, user, 24),
                            title: Row(children: [
                              Flexible(child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                              blueTick(user),
                            ]),
                            subtitle: Text('@' + value(user, 'username') + (value(user, 'bio').isNotEmpty ? ' · ' + value(user, 'bio') : ''), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cMuted)),
                            trailing: const Icon(Icons.arrow_outward_rounded, color: cBlue, size: 18),
                            onTap: () => Navigator.pop(ctx, user),
                          );
                        },
                      );
                    },
                  ),
            ),
          ]),
        ),
      ),
    );
    controller.dispose();
    if (selected == null || !mounted) return;
    await openUserProfile(value(selected, 'username'));
  }

  Widget profile() {
    final u = me; if (u == null) return Center(child: Text(error ?? 'در حال بارگذاری پروفایل...'));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 120, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF07162B), Color(0xFF123E70)])), child: const Icon(Icons.bolt, color: cBlue, size: 60)),
      const SizedBox(height: 16), Center(child: avatar(value(u, 'display_name', value(u, 'username', 'U')), u, 42)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(child: Text(value(u, 'display_name', value(u, 'username', 'کاربر')), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        blueTick(u),
      ]),
      Center(child: Text('@' + value(u, 'username'), style: const TextStyle(color: cMuted))),
      if (value(u, 'bio').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(value(u, 'bio'))),
      if (value(u, 'website').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(value(u, 'website'), style: const TextStyle(color: cBlue))),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => editProfile(u),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('ویرایش پروفایل'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () async => widget.logout(), icon: const Icon(Icons.logout), label: const Text('خروج از حساب')),
    ]);
  }
  Future<void> editProfile(Map<String, dynamic> user) async {
    final name = TextEditingController(text: value(user, 'display_name'));
    final bio = TextEditingController(text: value(user, 'bio'));
    final website = TextEditingController(text: value(user, 'website'));
    XFile? avatarFile;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, dialogSetState) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: const BorderSide(color: cLine)),
          title: const Text('شخصی‌سازی پروفایل'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [cBlue, Color(0xFF855DFF)])),
              child: CircleAvatar(
                radius: 38, backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                backgroundImage: avatarFile != null ? FileImage(File(avatarFile!.path)) : (value(user, 'avatar_url').startsWith('https://') ? NetworkImage(value(user, 'avatar_url')) : null) as ImageProvider?,
                child: avatarFile == null && !value(user, 'avatar_url').startsWith('https://') ? const Icon(Icons.person, size: 34, color: cBlue) : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1200);
                if (picked != null) dialogSetState(() => avatarFile = picked);
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(avatarFile == null ? 'انتخاب عکس پروفایل' : 'تغییر عکس انتخاب‌شده'),
            ),
            TextField(controller: name, maxLength: 80, decoration: const InputDecoration(labelText: 'نام نمایشی', prefixIcon: Icon(Icons.badge_outlined))),
            TextField(controller: bio, maxLength: 280, maxLines: 3, decoration: const InputDecoration(labelText: 'بیوگرافی', prefixIcon: Icon(Icons.edit_note))),
            TextField(controller: website, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'وب‌سایت یا لینک شخصی', prefixIcon: Icon(Icons.link))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره تغییرات')),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      try {
        int? avatarId;
        if (avatarFile != null) {
          final uploaded = await widget.api.uploadMedia(avatarFile!);
          avatarId = int.tryParse(uploaded['id'].toString());
          if (avatarId == null) throw const ApiException('شناسهٔ عکس از سرور دریافت نشد.');
        }
        final updated = await widget.api.updateProfile(
          displayName: name.text.trim(), bio: bio.text.trim(), website: website.text.trim(), avatarMediaId: avatarId,
        );
        if (mounted) setState(() => me = updated);
        if (mounted) toast('پروفایل ذخیره شد.');
      } on ApiException catch (e) {
        if (mounted) toast(e.message);
      }
    }
    name.dispose(); bio.dispose(); website.dispose();
  }

  @override Widget build(BuildContext context) {
    final pages = [home(), ListView(children: [Padding(padding: const EdgeInsets.fromLTRB(18, 18, 8, 8), child: Row(children: [const Expanded(child: Text('کاوش', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), IconButton(onPressed: searchUser, icon: const Icon(Icons.person_search, color: cBlue), tooltip: 'جست‌وجوی کاربر')])), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton.icon(onPressed: searchUser, icon: const Icon(Icons.search), label: const Text('جست‌وجو بر اساس نام کاربری'))), ...posts.map(card)]), notifications(), conversations(), profile()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      floatingActionButton: tab == 0
          ? FloatingActionButton(
              onPressed: posting ? null : compose,
              backgroundColor: cBlue,
              foregroundColor: const Color(0xFF06111D),
              child: const Icon(Icons.add_rounded),
            ).animate().scale(begin: const Offset(.78, .78), duration: 240.ms, curve: Curves.easeOutBack)
          : null,
      bottomNavigationBar: BinerLiquidGlass(
        borderRadius: BorderRadius.zero,
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: cBlue.withValues(alpha: .20),
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: cBlue), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.search_rounded, color: cBlue), label: 'کاوش'),
            NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded, color: cBlue), label: 'اعلان‌ها'),
            NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded, color: cBlue), label: 'پیام‌ها'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: cBlue), label: 'پروفایل'),
          ],
        ),
      ),
    );
  }
}
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.api, required this.conversationId, required this.currentUserId, required this.title});
  final BinerApi api;
  final int conversationId;
  final int currentUserId;
  final String title;
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  final items = <Map<String, dynamic>>[];
  bool loading = true, sending = false;
  String? error;
  Map<String, dynamic>? replyingTo;

  @override void initState() {
    super.initState();
    loadMessages();
  }

  @override void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    setState(() { loading = true; error = null; });
    try {
      await widget.api.markConversationRead(widget.conversationId);
      final result = await widget.api.messages(widget.conversationId);
      if (!mounted) return;
      setState(() { items..clear()..addAll(result); loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; loading = false; });
    }
  }

  Future<void> send() async {
    final raw = controller.text.trim();
    if (raw.isEmpty || sending) return;
    final reply = replyingTo;
    final text = reply == null ? raw : '↪ پاسخ به ${reply['sender_name'] ?? 'کاربر'}: "${(reply['body'] ?? '').toString().replaceAll('\n', ' ')}"\n$raw';
    controller.clear();
    FocusScope.of(context).unfocus();
    setState(() => replyingTo = null);
    setState(() => sending = true);
    try {
      final item = await widget.api.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() => items.add(item));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      });
    } on ApiException catch (e) {
      if (mounted) { controller.text = text; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> messageActions(Map<String, dynamic> item) async {
    final action = await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            decoration: BoxDecoration(color: const Color(0xEE0B1422), border: Border.all(color: cLine), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .6), borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.reply_rounded, color: cBlue), title: const Text('پاسخ به پیام'), subtitle: Text((item['body'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => Navigator.pop(ctx, 'reply')),
              ListTile(leading: const Icon(Icons.forward_rounded, color: Color(0xFF9B8CFF)), title: const Text('بازارسال در همین گفتگو'), onTap: () => Navigator.pop(ctx, 'forward')),
              ListTile(leading: const Icon(Icons.copy_rounded, color: cMuted), title: const Text('کپی متن پیام'), onTap: () => Navigator.pop(ctx, 'copy')),
            ]),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    final body = (item['body'] ?? '').toString();
    if (action == 'reply') {
      setState(() => replyingTo = item);
      FocusScope.of(context).requestFocus(FocusNode());
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: body));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('متن پیام کپی شد.')));
    } else if (action == 'forward') {
      try {
        final sent = await widget.api.sendMessage(widget.conversationId, '↗ پیام بازارسال‌شده\n$body');
        if (!mounted) return;
        setState(() => items.add(sent));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
        });
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Widget messageList() {
    if (loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: cBlue));
    }
    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: loadMessages, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final dark = Theme.of(context).brightness == Brightness.dark;
        final mine = item['sender_id']?.toString() == widget.currentUserId.toString();
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () => messageActions(item),
            child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .80),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              gradient: mine ? (dark ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xDD174A70), Color(0xCC252B57)]) : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD9F2FF), Color(0xFFDCDFFF)])) : (dark ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xCC18263A), Color(0xAA101A2B)]) : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xF8FFFFFF), Color(0xFFEFF4FA)])),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mine ? const Color(0x6639C5FF) : (dark ? const Color(0x553B5270) : const Color(0x223B5270))),
              boxShadow: [BoxShadow(color: (mine ? cBlue : Colors.black).withValues(alpha: dark ? .07 : .035), blurRadius: 16, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['body']?.toString() ?? '', style: const TextStyle(fontSize: 15, height: 1.42)),
                const SizedBox(height: 4),
                Text(item['created_at']?.toString() ?? '', style: const TextStyle(color: cMuted, fontSize: 10)),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [IconButton(onPressed: loadMessages, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Expanded(child: messageList()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'پیامت را بنویس...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : send,
                  icon: sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: cBlue),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF7FBFF), cBlue, Color(0xFF9B8CFF)]).createShader(bounds),
    child: const Text('BinerMention', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.45, color: Colors.white)),
  ).animate().fadeIn(duration: 350.ms).slideX(begin: -.04, duration: 350.ms);
}
