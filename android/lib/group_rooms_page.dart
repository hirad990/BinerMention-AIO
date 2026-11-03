import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_client.dart';

const _blue = Color(0xFF54C8FF);

class GroupRoomsPage extends StatefulWidget {
  const GroupRoomsPage({super.key, required this.api});
  final BinerApi api;
  @override State<GroupRoomsPage> createState() => _GroupRoomsPageState();
}
class _GroupRoomsPageState extends State<GroupRoomsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _future = widget.api.groups(); }
  void _reload() => setState(() => _future = widget.api.groups());

  Future<void> _create() async {
    final c = TextEditingController();
    final title = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('ساخت گروه جدید'),
      content: TextField(controller: c, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'نام گروه')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('ساخت گروه'))],
    ));
    c.dispose();
    if (title == null || title.isEmpty) return;
    try { await widget.api.createGroup(title); _reload(); }
    on ApiException catch (e) { if (mounted) _message(e.message); }
  }

  Future<void> _join() async {
    final c = TextEditingController();
    final link = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('ورود با لینک گروه'),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'bm:xxxxxxxxxxxxxxxx')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('ورود'))],
    ));
    c.dispose();
    if (link == null || link.isEmpty) return;
    try { await widget.api.joinGroup(link); _reload(); }
    on ApiException catch (e) { if (mounted) _message(e.message); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اتاق‌های گفتگو', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
      IconButton(onPressed: _join, icon: const Icon(Icons.link_rounded, color: _blue), tooltip: 'ورود با لینک'),
      IconButton(onPressed: _create, icon: const Icon(Icons.add_circle_outline_rounded, color: _blue), tooltip: 'ساخت گروه'),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _reload, child: const Text('تلاش دوباره'))])));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.forum_outlined, color: _blue, size: 54), const SizedBox(height: 14),
          const Text('هنوز عضو گروهی نیستی.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 7), const Text('گروه بساز یا با لینک داخلی bm: وارد گروه شو.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16), FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('ساخت اولین گروه')),
        ])));
        return RefreshIndicator(onRefresh: () async => _reload(), child: ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final g = items[index];
            final id = int.tryParse(g['id'].toString()) ?? 0;
            final title = g['title']?.toString() ?? 'گروه';
            final invite = g['invite_link']?.toString() ?? '';
            return ListTile(
              contentPadding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: _blue.withValues(alpha: .2))),
              leading: const CircleAvatar(backgroundColor: Color(0x2239C5FF), child: Icon(Icons.groups_rounded, color: _blue)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${g['members_count'] ?? 0} عضو  •  ${g['last_message'] ?? 'گفت‌وگوی تازه'}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: invite)); _message('لینک گروه کپی شد: $invite'); }, icon: const Icon(Icons.link_rounded, color: _blue)),
              onTap: id == 0 ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupChatPage(api: widget.api, groupId: id, title: title))),
            );
          },
        ));
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
  bool _loading = true, _sending = false;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _controller.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _load() async {
    try { final data = await widget.api.groupMessages(widget.groupId); if (mounted) setState(() { _items = data; _loading = false; }); }
    on ApiException catch (e) { if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } }
  }
  Future<void> _send() async {
    final text = _controller.text.trim(); if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try { await widget.api.sendGroupMessage(widget.groupId, text); _controller.clear(); await _load(); }
    on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
    body: Column(children: [
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: _blue)) : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(14), itemCount: _items.length, itemBuilder: (context, i) {
        final m = _items[i];
        return Align(alignment: AlignmentDirectional.centerStart, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 330), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withValues(alpha: .15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['display_name']?.toString() ?? m['username']?.toString() ?? 'کاربر', style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), Text(m['body']?.toString() ?? ''),
          const SizedBox(height: 4), Text(m['created_at']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ])));
      })),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'پیام گروه…', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
        const SizedBox(width: 8), IconButton.filled(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), style: IconButton.styleFrom(backgroundColor: _blue, foregroundColor: const Color(0xFF071426))),
      ]))),
    ]),
  );
}
