import 'localized_text.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'ui_kit.dart';
import 'app_preferences.dart';
import 'media_viewer.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.api, required this.username});
  final BinerApi api;
  final String username;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> posts = [];
  bool loading = true, followingBusy = false;
  String? error;
  int? myId;

  bool get dark => Theme.of(context).brightness == Brightness.dark;
  Color get surface => Theme.of(context).colorScheme.surfaceContainer;
  Color get muted => Theme.of(context).colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait<dynamic>([
        widget.api.userByUsername(widget.username),
        widget.api.me(),
      ]);
      final person = Map<String, dynamic>.from(results[0] as Map);
      final me = Map<String, dynamic>.from(results[1] as Map);
      final id = int.tryParse(person['id'].toString());
      final mine = int.tryParse(me['id'].toString());
      final userPosts = id == null ? <Map<String, dynamic>>[] : await widget.api.postsByUser(id);
      if (!mounted) return;
      setState(() {
        user = person;
        myId = mine;
        posts = userPosts;
        loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; loading = false; });
    } catch (_) {
      if (mounted) setState(() { error = 'بارگذاری پروفایل انجام نشد.'; loading = false; });
    }
  }

  String textOf(String key, [String fallback = '']) => user?[key]?.toString() ?? fallback;
  int countOf(String key) => int.tryParse(user?[key]?.toString() ?? '') ?? 0;
  bool get isSelf => myId != null && myId.toString() == textOf('id');
  bool get isFollowing {
    final value = user?['is_following'];
    return value == true || value == 1 || const {'1', 'true', 'yes'}.contains(value?.toString().trim().toLowerCase());
  }

  Future<void> toggleFollow() async {
    final id = int.tryParse(textOf('id'));
    if (id == null || followingBusy || isSelf) return;
    final before = isFollowing;
    setState(() {
      followingBusy = true;
      user!['is_following'] = !before;
      user!['followers_count'] = countOf('followers_count') + (before ? -1 : 1);
    });
    try {
      await widget.api.followUser(id, !before);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          user!['is_following'] = before;
          user!['followers_count'] = countOf('followers_count') + (before ? 1 : -1);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: BinerLocalizedText(e.message)));
      }
    } finally {
      if (mounted) setState(() => followingBusy = false);
    }
  }

  Widget avatar({double radius = 38}) {
    final url = textOf('avatar_url');
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [binerBlue, binerViolet, Color(0xFFFF7AC6)]),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        backgroundImage: url.startsWith('https://') ? ResizeImage.resizeIfNeeded(96, 96, NetworkImage(url)) : null,
        child: url.startsWith('https://')
            ? null
            : Icon(Icons.person_rounded, size: radius, color: dark ? binerBlue : const Color(0xFF4776A7)),
      ),
    );
  }

  Widget connectionCount(String label, String key, bool followers) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: key == 'posts_count' ? null : () => showConnections(followers),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(children: [
            BinerLocalizedText(countOf(key).toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            BinerLocalizedText(label, style: TextStyle(color: muted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Future<void> showConnections(bool followers) async {
    final id = int.tryParse(textOf('id'));
    if (id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * .68,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: binerBlue.withValues(alpha: .35)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Icon(followers ? Icons.people_alt_rounded : Icons.person_add_alt_1_rounded, color: binerBlue),
              const SizedBox(width: 10),
              BinerLocalizedText(followers ? binerText('دنبال‌کنندگان',en:'Followers',ar:'المتابعون',tr:'Takipçiler') : binerText('دنبال‌شوندگان',en:'Following',ar:'المتابَعون',tr:'Takip edilenler'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.api.userConnections(id, followers: followers),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: BinerLocalizedText(snapshot.error.toString(), textAlign: TextAlign.center));
                final users = snapshot.data ?? const <Map<String, dynamic>>[];
                if (users.isEmpty) return Center(child: BinerLocalizedText(binerText('هنوز کسی اینجا نیست.',en:'Nothing here yet.',ar:'لا يوجد شيء هنا بعد.',tr:'Henüz burada kimse yok.')));
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: binerBlue.withValues(alpha: .12)),
                  itemBuilder: (_, i) {
                    final person = users[i];
                    final name = person['display_name']?.toString().trim().isNotEmpty == true
                        ? person['display_name'].toString()
                        : person['username']?.toString() ?? 'کاربر';
                    final url = person['avatar_url']?.toString() ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: url.startsWith('https://') ? NetworkImage(url) : null,
                        child: url.startsWith('https://') ? null : const Icon(Icons.person_outline),
                      ),
                      title: BinerLocalizedText(name),
                      subtitle: BinerLocalizedText("@${person['username'] ?? ''}", style: TextStyle(color: muted)),
                      onTap: () {
                        final username = person['username']?.toString() ?? '';
                        if (username.isNotEmpty) {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => UserProfilePage(api: widget.api, username: username),
                          ));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget postCard(Map<String, dynamic> post) {
    final body = post['body']?.toString() ?? '';
    final display = post['display_name']?.toString() ?? post['username']?.toString() ?? 'کاربر';
    final mediaUrl = post['media_url']?.toString() ?? '';
    final mime = post['mime_type']?.toString() ?? '';
    final isVideo = mime.startsWith('video/') ||
        RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(mediaUrl);

    return BinerSurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 7),
      padding: const EdgeInsets.all(15),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bolt_rounded, color: binerBlue, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: BinerLocalizedText(display, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            BinerLocalizedText(post['created_at']?.toString() ?? '',
                style: TextStyle(color: muted, fontSize: 10)),
          ]),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: BinerLocalizedText(body, style: const TextStyle(fontSize: 14, height: 1.55)),
            ),
          if (mediaUrl.startsWith('https://'))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () => BinerMediaViewer.open(
                  context, url: mediaUrl, mimeType: mime, title: 'پست $display',
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: isVideo
                      ? Container(
                          height: 170, color: Colors.black,
                          child: const Center(child: Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: 46)),
                        )
                      : Image.network(
                          mediaUrl,
                          fit: BoxFit.contain,
                          cacheWidth: 720,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 90,
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.favorite_border_rounded, size: 17, color: muted),
            const SizedBox(width: 5),
            BinerLocalizedText(post['likes_count']?.toString() ?? '0',
                style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(width: 18),
            Icon(Icons.repeat_rounded, size: 17, color: muted),
            const SizedBox(width: 5),
            BinerLocalizedText(post['reposts_count']?.toString() ?? '0',
                style: TextStyle(color: muted, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BinerPreferences.instance,
    builder: (context, _) => _buildProfile(),
  );

  Widget _buildProfile() {
    final displayName = textOf('display_name', textOf('username', 'کاربر'));
    return Scaffold(backgroundColor: binerScaffoldBackground(context),
      body: SafeArea(
        child: loading && user == null
            ? const Center(child: BinerSkeleton(lines: 3))
            : error != null && user == null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    BinerLocalizedText(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: load, icon: const Icon(Icons.refresh_rounded), label: BinerLocalizedText(binerText('تلاش دوباره',en:'Try again',ar:'حاول مرة أخرى',tr:'Tekrar dene'))),
                  ])))
                : RefreshIndicator(
                    onRefresh: load,
                    child: CustomScrollView(slivers: [
                      SliverToBoxAdapter(
                        child: Stack(children: [
                          Container(
                            height: 185,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF102A49), Color(0xFF345BC5), Color(0xFF8B75FF)]),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
                            ),
                            child: Stack(children: [
                              Positioned(right: 24, top: 22, child: Icon(Icons.bubble_chart_rounded, size: 96, color: Colors.white.withValues(alpha: .08))),
                              Positioned(left: 24, bottom: 18, child: Icon(Icons.auto_awesome_rounded, size: 42, color: Colors.white.withValues(alpha: .16))),
                            ]),
                          ),
                          Positioned(left: 8, top: 8, child: IconButton.filledTonal(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded))),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 130, 20, 12),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              avatar(radius: 43),
                              const SizedBox(width: 14),
                              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                BinerLocalizedText(displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                Row(children: [
                                  Flexible(child: BinerLocalizedText("@${textOf('username')}", style: TextStyle(color: muted))),
                                  if (user?['BlueTick'] == true || user?['BlueTick'] == 1) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, color: Color(0xFF1D9BF0), size: 17)),
                                ]),
                              ]))),
                            ]),
                          ),
                        ]),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            if (textOf('bio').isNotEmpty) BinerLocalizedText(textOf('bio'), style: const TextStyle(fontSize: 14, height: 1.5)),
                            if (textOf('website').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
                              const Icon(Icons.link_rounded, size: 17, color: binerBlue),
                              const SizedBox(width: 6),
                              Expanded(child: BinerLocalizedText(textOf('website'), style: const TextStyle(color: binerBlue))),
                            ])),
                            const SizedBox(height: 10),
                            Row(children: [
                              connectionCount(binerText('پست',en:'Posts',ar:'المنشورات',tr:'Gönderi'), 'posts_count', false),
                              connectionCount(binerText('دنبال‌کننده',en:'Followers',ar:'المتابعون',tr:'Takipçi'), 'followers_count', true),
                              connectionCount(binerText('دنبال‌شونده',en:'Following',ar:'المتابَعون',tr:'Takip edilen'), 'following_count', false),
                            ]),
                            if (!isSelf) SizedBox(
                              height: 46,
                              child: FilledButton.icon(
                                onPressed: followingBusy ? null : toggleFollow,
                                icon: Icon(isFollowing ? Icons.person_remove_alt_1_rounded : Icons.person_add_alt_1_rounded),
                                label: BinerLocalizedText(followingBusy ? binerText('کمی صبر کن…',en:'Please wait…',ar:'يرجى الانتظار…',tr:'Lütfen bekle…') : isFollowing ? binerText('دنبال می‌کنی',en:'Following',ar:'تتابعه',tr:'Takip ediliyor') : binerText('دنبال‌کردن',en:'Follow',ar:'متابعة',tr:'Takip et')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isFollowing ? Theme.of(context).colorScheme.surfaceContainerHigh : Theme.of(context).colorScheme.primary,
                                  foregroundColor: isFollowing ? Theme.of(context).colorScheme.onSurface : const Color(0xFF06111D),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Row(children: [
                            const Icon(Icons.grid_view_rounded, color: binerBlue),
                            const SizedBox(width: 8),
                            BinerLocalizedText(binerText('پست‌ها',en:'Posts',ar:'المنشورات',tr:'Gönderiler'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const Spacer(),
                            BinerLocalizedText('${posts.length}', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      if (posts.isEmpty)
                        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(34), child: Center(child: BinerLocalizedText('هنوز پستی منتشر نشده.', style: TextStyle(color: muted)))))
                      else
                        SliverList(delegate: SliverChildBuilderDelegate((context, index) => postCard(posts[index]), childCount: posts.length)),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ]),
                  ),
      ),
    );
  }
}
