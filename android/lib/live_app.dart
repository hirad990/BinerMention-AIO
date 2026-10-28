import 'package:flutter/material.dart';
import 'api_client.dart';

const cBg = Color(0xFF050A12), cPanel = Color(0xFF0A111E), cLine = Color(0xFF1E2A3D), cBlue = Color(0xFF00A8FE), cMuted = Color(0xFF8796AD);

class BinerLiveApp extends StatefulWidget {
  const BinerLiveApp({super.key});
  @override State<BinerLiveApp> createState() => _BinerLiveAppState();
}
class _BinerLiveAppState extends State<BinerLiveApp> {
  final api = BinerApi();
  bool ready = false, loggedIn = false;
  @override void initState() { super.initState(); init(); }
  Future<void> init() async {
    await api.restoreSession();
    if (api.isAuthenticated) { try { await api.me(); loggedIn = true; } on ApiException { loggedIn = false; } }
    if (mounted) setState(() => ready = true);
  }
  void signedIn() => setState(() => loggedIn = true);
  Future<void> logout() async { await api.logout(); if (mounted) setState(() => loggedIn = false); }
  @override void dispose() { api.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'BinerMention', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: cBg, colorScheme: const ColorScheme.dark(primary: cBlue, surface: cPanel), useMaterial3: true),
    home: !ready ? const Scaffold(body: Center(child: CircularProgressIndicator(color: cBlue))) : loggedIn ? LiveHome(api: api, logout: logout) : LiveAuth(api: api, onDone: signedIn),
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
      Center(child: Container(width: 78, height: 78, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [cBlue, Color(0xFF2554E8)])), child: const Icon(Icons.bolt, size: 48))),
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
  const LiveHome({super.key, required this.api, required this.logout});
  final BinerApi api; final Future<void> Function() logout;
  @override State<LiveHome> createState() => _LiveHomeState();
}
class _LiveHomeState extends State<LiveHome> {
  int tab = 0; bool loading = true, posting = false; String? error;
  final posts = <Map<String, dynamic>>[]; Map<String, dynamic>? me;
  @override void initState() { super.initState(); refresh(); profile(); }
  Future<void> profile() async { try { final u = await widget.api.me(); if (mounted) setState(() => me = u); } on ApiException catch (e) { if (mounted) setState(() => error = e.message); } }
  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try { final data = await widget.api.posts(); if (mounted) setState(() { posts..clear()..addAll(data); }); }
    on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> compose() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: cPanel, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('پست جدید', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 5, maxLength: 280, decoration: const InputDecoration(hintText: 'چه خبر؟', border: InputBorder.none)),
        Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('انتشار'))),
      ]),
    ));
    final body = controller.text.trim(); controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => posting = true);
    try { final item = await widget.api.createPost(text); if (mounted) setState(() => posts.insert(0, item)); }
    on ApiException catch (e) { if (mounted) toast(e.message); }
    finally { if (mounted) setState(() => posting = false); }
  }
  Future<void> toggle(Map<String, dynamic> p, String actionName) async {
    final flag = actionName == 'like' ? 'liked' : 'reposted', count = actionName == 'like' ? 'likes_count' : 'reposts_count';
    final id = int.tryParse(p['id'].toString()); if (id == null) return;
    final oldFlag = p[flag] == true, oldCount = int.tryParse((p[count] ?? 0).toString()) ?? 0;
    setState(() { p[flag] = !oldFlag; p[count] = oldCount + (oldFlag ? -1 : 1); });
    try { await widget.api.togglePostAction(id, actionName, !oldFlag); }
    on ApiException catch (e) { if (!mounted) return; setState(() { p[flag] = oldFlag; p[count] = oldCount; }); toast(e.message); }
  }
  String value(Map<String, dynamic> m, String k, [String fallback = '']) => m[k]?.toString() ?? fallback;
  String fmt(dynamic raw) { final n = int.tryParse(raw.toString()) ?? 0; if (n >= 1000) return (n / 1000).toStringAsFixed(1) + 'K'; return n.toString(); }
  Widget avatar(String n) => CircleAvatar(backgroundColor: const Color(0xFF17334F), child: Text(n.isEmpty ? '?' : n[0].toUpperCase()));
  Widget card(Map<String, dynamic> p) {
    final name = value(p, 'display_name', value(p, 'username', 'کاربر'));
    final body = value(p, 'body');
    final liked = p['liked'] == true, reposted = p['reposted'] == true;
    return Container(padding: const EdgeInsets.all(15), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cLine)), color: cBg), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      avatar(name), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name + '  @' + value(p, 'username', 'user'), style: const TextStyle(fontWeight: FontWeight.bold)),
        if (body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text(body, style: const TextStyle(height: 1.5))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton.icon(onPressed: () => toast('پاسخ‌ها هنوز به رابط کاربری متصل نشده‌اند.'), icon: const Icon(Icons.chat_bubble_outline, size: 17), label: Text(fmt(p['replies_count'] ?? 0))),
          TextButton.icon(onPressed: () => toggle(p, 'repost'), icon: Icon(Icons.repeat, size: 17, color: reposted ? cBlue : cMuted), label: Text(fmt(p['reposts_count'] ?? 0))),
          TextButton.icon(onPressed: () => toggle(p, 'like'), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 17, color: liked ? Colors.pinkAccent : cMuted), label: Text(fmt(p['likes_count'] ?? 0))),
        ]),
      ])),
    ]));
  }
  Widget home() => Column(children: [
    const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Brand())),
    const Divider(height: 1, color: cLine),
    Expanded(child: loading && posts.isEmpty ? const Center(child: CircularProgressIndicator(color: cBlue)) : error != null && posts.isEmpty
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: refresh, child: const Text('تلاش دوباره'))]))
      : RefreshIndicator(onRefresh: refresh, child: posts.isEmpty ? ListView(children: const [SizedBox(height: 100), Center(child: Text('هنوز پستی وجود ندارد.'))]) : ListView.builder(itemCount: posts.length, itemBuilder: (_, i) => card(posts[i])))),
  ]);
  Widget notifications() => FutureBuilder<List<Map<String, dynamic>>>(future: widget.api.notifications(), builder: (context, s) {
    if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
    if (s.hasError) return Center(child: Text(s.error.toString()));
    final items = s.data ?? [];
    return ListView(children: [const Padding(padding: EdgeInsets.all(18), child: Text('اعلان‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      if (items.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('اعلان تازه‌ای نداری.'))),
      ...items.map((n) => ListTile(leading: avatar(value(n, 'actor_display_name', value(n, 'actor_username', 'U'))), title: Text(value(n, 'actor_display_name', value(n, 'actor_username', 'کاربر')) + ' • ' + value(n, 'type', 'تعامل جدید')), subtitle: Text(value(n, 'created_at'), style: const TextStyle(color: cMuted)))),
    ]);
  });
  Widget conversations() => FutureBuilder<List<Map<String, dynamic>>>(future: widget.api.conversations(), builder: (context, s) {
    if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
    if (s.hasError) return Center(child: Text(s.error.toString()));
    final items = s.data ?? [];
    return ListView(children: [const Padding(padding: EdgeInsets.all(18), child: Text('پیام‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      if (items.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('هنوز گفت‌وگویی نداری.'))),
      ...items.map((c) => ListTile(leading: avatar('M'), title: Text('گفت‌وگو #' + value(c, 'id')), subtitle: Text(value(c, 'last_message', 'گفت‌وگوی جدید')), onTap: () => toast('نمای پیام‌ها در مرحله بعدی تکمیل می‌شود.'))),
    ]);
  });
  Widget profile() {
    final u = me; if (u == null) return Center(child: Text(error ?? 'در حال بارگذاری پروفایل...'));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 120, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF07162B), Color(0xFF123E70)])), child: const Icon(Icons.bolt, color: cBlue, size: 60)),
      const SizedBox(height: 16), avatar(value(u, 'display_name', value(u, 'username', 'U'))),
      Text(value(u, 'display_name', value(u, 'username', 'کاربر')), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text('@' + value(u, 'username'), style: const TextStyle(color: cMuted)),
      if (value(u, 'bio').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(value(u, 'bio'))),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () async => widget.logout(), icon: const Icon(Icons.logout), label: const Text('خروج از حساب')),
    ]);
  }
  @override Widget build(BuildContext context) {
    final pages = [home(), ListView(children: [const Padding(padding: EdgeInsets.all(18), child: Text('کاوش', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), ...posts.map(card)]), notifications(), conversations(), profile()];
    return Scaffold(body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      floatingActionButton: tab == 0 ? FloatingActionButton(onPressed: posting ? null : compose, backgroundColor: cBlue, child: const Icon(Icons.add)) : null,
      bottomNavigationBar: NavigationBar(height: 66, backgroundColor: cBg, indicatorColor: cBlue.withValues(alpha: .14), selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: cBlue), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search, color: cBlue), label: 'کاوش'),
        NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications, color: cBlue), label: 'اعلان‌ها'),
        NavigationDestination(icon: Icon(Icons.mail_outline), selectedIcon: Icon(Icons.mail, color: cBlue), label: 'پیام‌ها'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: cBlue), label: 'پروفایل'),
      ]),
    );
  }
}
class Brand extends StatelessWidget {
  const Brand({super.key});
  @override Widget build(BuildContext context) => RichText(text: const TextSpan(style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white), children: [TextSpan(text: 'Biner'), TextSpan(text: 'Mention', style: TextStyle(color: cBlue))]));
}
