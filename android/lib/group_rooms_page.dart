import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'api_client.dart';
import 'app_preferences.dart';
import 'biner_ai_page.dart';
import 'media_editor.dart';
import 'media_viewer.dart';
import 'ui_kit.dart';

class GroupRoomsPage extends StatefulWidget {
  const GroupRoomsPage({super.key, required this.api});
  final BinerApi api;
  @override State<GroupRoomsPage> createState() => _GroupRoomsPageState();
}

class _GroupRoomsPageState extends State<GroupRoomsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _future = widget.api.groups(); }

  Future<void> _reload() async {
    final next = widget.api.groups();
    setState(() => _future = next);
    await next;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ساخت اتاق گفتگو'),
        content: TextField(controller: controller, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'نام گروه')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ساخت گروه')),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    try { await widget.api.createGroup(title); await _reload(); }
    on ApiException catch (e) { if (mounted) _message(e.message); }
  }

  Future<void> _join() async {
    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ورود به گروه'),
        content: TextField(controller: controller, autofocus: true, autocorrect: false, decoration: const InputDecoration(hintText: 'bm:xxxxxxxxxxxxxxxx')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ورود')),
        ],
      ),
    );
    controller.dispose();
    if (link == null || link.isEmpty) return;
    try { await widget.api.joinGroup(link); await _reload(); }
    on ApiException catch (e) { if (mounted) _message(e.message); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('اتاق‌های گفتگو'),
      actions: [
        IconButton(tooltip: 'ورود با لینک', onPressed: _join, icon: const Icon(Icons.link_rounded)),
        IconButton(tooltip: 'ساخت گروه', onPressed: _create, icon: const Icon(Icons.add_circle_outline_rounded)),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListView(children: [BinerSkeleton(lines: 2), BinerSkeleton(lines: 2), BinerSkeleton(lines: 2)]);
        }
        if (snapshot.hasError) {
          return BinerEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'گروه‌ها بارگذاری نشدند',
            description: 'اتصال API را بررسی کن و دوباره تلاش کن.',
            action: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
          );
        }
        final groups = snapshot.data ?? const <Map<String, dynamic>>[];
        if (groups.isEmpty) {
          return BinerEmptyState(
            icon: Icons.forum_outlined,
            title: 'هنوز عضو گروهی نیستی',
            description: 'یک اتاق گفتگو بساز یا با لینک داخلی bm: به گروهی بپیوند.',
            action: Wrap(spacing: 10, children: [
              FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('ساخت گروه')),
              OutlinedButton.icon(onPressed: _join, icon: const Icon(Icons.link_rounded), label: const Text('ورود با لینک')),
            ]),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            itemCount: groups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const BinerSectionHeader(
                  title: 'گروه‌های تو',
                  subtitle: 'گفتگوهای گروهی خصوصی و قابل مدیریت',
                );
              }
              final group = groups[index - 1];
              final id = int.tryParse(group['id'].toString()) ?? 0;
              final title = group['title']?.toString() ?? 'گروه';
              final invite = group['invite_link']?.toString() ?? '';
              return BinerSurfaceCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                radius: 20,
                onTap: id == 0 ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupChatPage(api: widget.api, groupId: id, title: title))),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF54C8FF), Color(0xFF7868E8)]),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF071426), size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${group['members_count'] ?? 0} عضو  ·  ${group['last_message'] ?? 'گفت‌وگوی تازه'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                  IconButton(
                    tooltip: 'کپی لینک گروه',
                    onPressed: invite.isEmpty ? null : () async {
                      await Clipboard.setData(ClipboardData(text: invite));
                      if (context.mounted) _message('لینک گروه کپی شد.');
                    },
                    icon: const Icon(Icons.link_rounded),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ]),
              );
            },
          ),
        );
      },
    ),
  );
}

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.api, required this.groupId, required this.title});
  final BinerApi api;
  final int groupId;
  final String title;
  @override State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _items = [];
  int? _myId;
  bool _loading = true, _sending = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _controller.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([widget.api.groupMessages(widget.groupId), widget.api.me()]);
      if (!mounted) return;
      final me = Map<String, dynamic>.from(results[1] as Map);
      setState(() {
        _items = (results[0] as List).cast<Map<String, dynamic>>();
        _myId = int.tryParse(me['id'].toString());
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _send({XFile? attachment}) async {
    final text = _controller.text.trim();
    if ((text.isEmpty && attachment == null) || _sending) return;
    setState(() => _sending = true);
    try {
      int? mediaId;
      if (attachment != null) {
        final uploaded = await widget.api.uploadMedia(attachment);
        mediaId = int.tryParse(uploaded['id'].toString());
        if (mediaId == null) throw const ApiException('شناسه رسانه دریافت نشد.');
      }
      await widget.api.sendGroupMessage(widget.groupId, text, mediaId: mediaId);
      _controller.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openInvite(String code) async {
    try {
      final result = await widget.api.joinGroup(code);
      final id = int.tryParse(result['group_id'].toString());
      if (!mounted || id == null) return;
      final groups = await widget.api.groups();
      Map<String, dynamic>? group;
      for (final item in groups) {
        if (int.tryParse(item['id'].toString()) == id) { group = item; break; }
      }
      if (group == null || !mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupChatPage(api: widget.api, groupId: id, title: group!['title']?.toString() ?? 'گروه')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _messageBody(String body) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'bm:[a-fA-F0-9]{16}');
    var cursor = 0;
    for (final match in pattern.allMatches(body)) {
      if (match.start > cursor) spans.add(TextSpan(text: body.substring(cursor, match.start)));
      final token = match.group(0)!;
      final code = token.substring(3);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => _openInvite(code),
          child: Text(token, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
        ),
      ));
      cursor = match.end;
    }
    if (cursor < body.length) spans.add(TextSpan(text: body.substring(cursor)));
    return RichText(text: TextSpan(style: TextStyle(fontSize: 14, height: 1.45, color: Theme.of(context).colorScheme.onSurface), children: spans));
  }

  String _dayLabel(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final local = date.toLocal();
    return DateFormat('d MMMM yyyy', BinerPreferences.instance.locale.languageCode).format(local);
  }

  bool _sameDay(String a, String b) {
    final first = DateTime.tryParse(a)?.toLocal();
    final second = DateTime.tryParse(b)?.toLocal();
    return first != null && second != null && first.year == second.year && first.month == second.month && first.day == second.day;
  }

  Widget _message(Map<String, dynamic> message, bool mine) {
    final mediaUrl = message['media_url']?.toString() ?? '';
    final mime = message['mime_type']?.toString() ?? '';
    final video = mime.startsWith('video/') || RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(mediaUrl);
    final time = DateTime.tryParse(message['created_at']?.toString() ?? '');
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xDD174A70), Color(0xCC252B57)])
              : (Theme.of(context).brightness == Brightness.dark ? const LinearGradient(colors: [Color(0xE6101A29), Color(0xDD111827)]) : null),
          color: mine ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18),
          ),
          border: Border.all(color: mine ? const Color(0x6654C8FF) : Theme.of(context).dividerColor.withValues(alpha: .4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(message['display_name']?.toString() ?? message['username']?.toString() ?? 'کاربر', style: const TextStyle(color: Color(0xFF54C8FF), fontSize: 11, fontWeight: FontWeight.w900))),
          if (mediaUrl.startsWith('https://')) ...[
            GestureDetector(
              onTap: () => BinerMediaViewer.open(context, url: mediaUrl, mimeType: mime, title: widget.title),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: video
                    ? Container(width: 220, height: 128, color: Colors.black, child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48)))
                    : Image.network(mediaUrl, width: 220, height: 170, fit: BoxFit.cover, cacheWidth: 660, errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 90, child: Icon(Icons.broken_image_outlined))),
              ),
            ),
            const SizedBox(height: 7),
          ],
          if ((message['body']?.toString() ?? '').isNotEmpty) _messageBody(message['body']?.toString() ?? ''),
          const SizedBox(height: 5),
          Align(alignment: AlignmentDirectional.centerEnd, child: Text(time == null ? '' : DateFormat('HH:mm').format(time.toLocal()), style: TextStyle(color: mine ? Colors.white60 : Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 9))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF54C8FF), Color(0xFF7868E8)]), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.groups_rounded, color: Color(0xFF071426))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text('${_items.length} پیام اخیر', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ])),
      ]),
      actions: [
        IconButton(tooltip: 'BinerAI', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BinerAIPage(api: widget.api))), icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B8CFF))),
        IconButton(tooltip: 'به‌روزرسانی', onPressed: () => _load(showLoading: true), icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: Column(children: [
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF54C8FF)))
            : RefreshIndicator(
                onRefresh: () => _load(),
                child: ListView.builder(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  itemCount: _items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(padding: EdgeInsets.only(bottom: 12), child: Center(child: Text('پیام‌ها برای اعضای گروه قابل مشاهده‌اند.', style: TextStyle(color: Colors.grey, fontSize: 11))));
                    }
                    final item = _items[index - 1];
                    final mine = item['sender_id']?.toString() == _myId?.toString();
                    final currentDate = item['created_at']?.toString() ?? '';
                    final previousDate = index > 1 ? _items[index - 2]['created_at']?.toString() ?? '' : '';
                    final showDate = index == 1 || !_sameDay(currentDate, previousDate);
                    return Column(children: [
                      if (showDate) Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .8), borderRadius: BorderRadius.circular(30), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
                          child: Text(_dayLabel(currentDate), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      _message(item, mine),
                    ]);
                  },
                ),
              ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
          child: BinerSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            radius: 24,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(
                tooltip: 'ارسال عکس یا ویدیو',
                onPressed: _sending ? null : () async {
                  final file = await BinerMediaEditor.pickMedia();
                  if (file != null && mounted) await _send(attachment: file);
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
              Expanded(child: TextField(
                controller: _controller,
                minLines: 1, maxLines: 5,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'پیام گروه…', filled: false, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
              )),
              const SizedBox(width: 5),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF54C8FF), foregroundColor: const Color(0xFF071426)),
                icon: _sending ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward_rounded),
              ),
            ]),
          ),
        ),
      ),
    ]),
  );
}
