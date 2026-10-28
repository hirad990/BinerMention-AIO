import 'package:flutter/material.dart';
import 'api_client.dart';
import 'package:image_picker/image_picker.dart';

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
  int tab = 0; bool loading = true, posting = false, followingFeed = false; String? error;
  final posts = <Map<String, dynamic>>[]; Map<String, dynamic>? me;
  @override void initState() { super.initState(); refresh(); loadProfile(); }
  Future<void> loadProfile() async { try { final u = await widget.api.me(); if (mounted) setState(() => me = u); } on ApiException catch (e) { if (mounted) setState(() => error = e.message); } }
  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try { final data = await widget.api.posts(following: followingFeed); if (mounted) setState(() { posts..clear()..addAll(data); }); }
    on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> compose({int? replyToId}) async {
    final controller = TextEditingController();
    XFile? attachment;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cPanel,
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
                  decoration: const InputDecoration(hintText: 'چه خبر؟', border: InputBorder.none)),
              if (attachment != null)
                ListTile(leading: const Icon(Icons.image, color: cBlue), title: Text(attachment!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => sheetSetState(() => attachment = null))),
              Row(children: [
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
        if (value(p, 'media_url').startsWith('https://')) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(value(p, 'media_url'), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton.icon(onPressed: () => compose(replyToId: int.tryParse(p['id'].toString())), icon: const Icon(Icons.chat_bubble_outline, size: 17), label: Text(fmt(p['replies_count'] ?? 0))),
          TextButton.icon(onPressed: () => toggle(p, 'repost'), icon: Icon(Icons.repeat, size: 17, color: reposted ? cBlue : cMuted), label: Text(fmt(p['reposts_count'] ?? 0))),
          TextButton.icon(onPressed: () => toggle(p, 'like'), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 17, color: liked ? Colors.pinkAccent : cMuted), label: Text(fmt(p['likes_count'] ?? 0))),
        ]),
      ])),
    ]));
  }
  Widget home() => Column(
    children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Brand())),
      Row(children: [
        Expanded(child: InkWell(
          onTap: () { if (followingFeed) { setState(() => followingFeed = false); refresh(); } },
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('برای تو', style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? cMuted : Colors.white))),
            Container(height: 3, width: 82, decoration: BoxDecoration(color: followingFeed ? Colors.transparent : cBlue, borderRadius: BorderRadius.circular(3))),
          ]),
        )),
        Expanded(child: InkWell(
          onTap: () { if (!followingFeed) { setState(() => followingFeed = true); refresh(); } },
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('دنبال‌شونده‌ها', style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? Colors.white : cMuted))),
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
      return const Center(child: CircularProgressIndicator(color: cBlue));
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
      ...items.map((n) => ListTile(leading: avatar(value(n, 'actor_display_name', value(n, 'actor_username', 'U'))), title: Text(value(n, 'actor_display_name', value(n, 'actor_username', 'کاربر')) + ' • ' + value(n, 'type', 'تعامل جدید')), subtitle: Text(value(n, 'created_at'), style: const TextStyle(color: cMuted)))),
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
    final username = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('جست‌وجوی کاربر'),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          decoration: const InputDecoration(prefixText: '@', hintText: 'نام کاربری'),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('جست‌وجو')),
        ],
      ),
    );
    if (username == null || username.trim().isEmpty || !mounted) {
      controller.dispose();
      return;
    }
    try {
      final user = await widget.api.userByUsername(username.trim().replaceFirst('@', ''));
      if (!mounted) return;
      final selfId = int.tryParse(value(me ?? {}, 'id', '-1')) ?? -1;
      final userId = int.tryParse(user['id'].toString()) ?? -1;
      var following = user['is_following'] == true;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, dialogSetState) => AlertDialog(
            title: Text(value(user, 'display_name', value(user, 'username', 'کاربر'))),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('@' + value(user, 'username'), style: const TextStyle(color: cMuted)),
              if (value(user, 'bio').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(value(user, 'bio'))),
              const SizedBox(height: 10),
              Text('\${value(user, 'followers_count', '0')} دنبال‌کننده • \${value(user, 'following_count', '0')} دنبال‌شونده'),
              if (value(user, 'website').isNotEmpty) Text(value(user, 'website'), style: const TextStyle(color: cBlue)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
              if (selfId != userId && selfId >= 0)
                FilledButton(
                  onPressed: () async {
                    try {
                      await widget.api.followUser(userId, !following);
                      dialogSetState(() => following = !following);
                    } on ApiException catch (e) {
                      if (mounted) toast(e.message);
                    }
                  },
                  child: Text(following ? 'دنبال‌نکردن' : 'دنبال‌کردن'),
                ),
              if (selfId == userId) const Padding(padding: EdgeInsets.all(8), child: Text('این حساب خودت است.')),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) toast(e.message);
    } finally {
      controller.dispose();
    }
  }

  Widget profile() {
    final u = me; if (u == null) return Center(child: Text(error ?? 'در حال بارگذاری پروفایل...'));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 120, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF07162B), Color(0xFF123E70)])), child: const Icon(Icons.bolt, color: cBlue, size: 60)),
      const SizedBox(height: 16), avatar(value(u, 'display_name', value(u, 'username', 'U'))),
      Text(value(u, 'display_name', value(u, 'username', 'کاربر')), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text('@' + value(u, 'username'), style: const TextStyle(color: cMuted)),
      if (value(u, 'bio').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(value(u, 'bio'))),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش پروفایل'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, maxLength: 80, decoration: const InputDecoration(labelText: 'نام نمایشی')),
          TextField(controller: bio, maxLength: 280, maxLines: 3, decoration: const InputDecoration(labelText: 'معرفی کوتاه')),
          TextField(controller: website, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'وب‌سایت')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final updated = await widget.api.updateProfile(displayName: name.text.trim(), bio: bio.text.trim(), website: website.text.trim());
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
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    controller.clear();
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
        final mine = item['sender_id']?.toString() == widget.currentUserId.toString();
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? const Color(0xFF103B5B) : cPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['body']?.toString() ?? '', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 4),
                Text(item['created_at']?.toString() ?? '', style: const TextStyle(color: cMuted, fontSize: 10)),
              ],
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
      backgroundColor: cBg,
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
                      fillColor: cPanel,
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
  @override Widget build(BuildContext context) => RichText(text: const TextSpan(style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white), children: [TextSpan(text: 'Biner'), TextSpan(text: 'Mention', style: TextStyle(color: cBlue))]));
}
