import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_preferences.dart';
import 'text_tools.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_client.dart';
import 'ui_kit.dart';
import 'profile_page.dart';
import 'biner_ai_page.dart';
import 'insights_page.dart';
import 'group_rooms_page.dart';
import 'media_editor.dart';
import 'media_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const cBg = Color(0xFF000000), cPanel = Color(0xF20A0A0C), cLine = Color(0x4439C5FF), cBlue = Color(0xFF54C8FF), cMuted = Color(0xFF9A9AA8), cGlass = Color(0xAA101014);

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
    await BinerMediaEditor.recoverLostData();
    await BinerPreferences.instance.load();
    final prefs = await SharedPreferences.getInstance();
    themeMode = prefs.getBool('biner_theme_dark') == false ? ThemeMode.light : ThemeMode.dark;
    await api.restoreSession();
    if (api.isAuthenticated) { try { await api.me(); loggedIn = true; } on ApiException { loggedIn = false; } }
    if (mounted) setState(() => ready = true);
  }
  void signedIn() => setState(() => loggedIn = true);
  Future<void> logout() async { await api.logout(); if (mounted) setState(() => loggedIn = false); }
  @override void dispose() { api.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: BinerPreferences.instance,
    builder: (context, _) => MaterialApp(
    locale: BinerPreferences.instance.locale,
    supportedLocales: const [Locale('fa'), Locale('en'), Locale('ar'), Locale('tr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    title: 'BinerMention',
    debugShowCheckedModeBanner: false,
    theme: buildBinerTheme(Brightness.light, seedColor: BinerPreferences.instance.accent),
    darkTheme: buildBinerTheme(Brightness.dark, seedColor: BinerPreferences.instance.accent),
    themeMode: themeMode,
    builder: (context, child) => Directionality(textDirection: BinerPreferences.instance.direction, child: BinerBackdrop(child: child ?? const SizedBox.shrink())),
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
  ));
}

class LiveAuth extends StatefulWidget {
  const LiveAuth({super.key, required this.api, required this.onDone});
  final BinerApi api; final VoidCallback onDone;
  @override State<LiveAuth> createState() => _LiveAuthState();
}
class _LiveAuthState extends State<LiveAuth> with TickerProviderStateMixin {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(), email = TextEditingController(), password = TextEditingController(), displayName = TextEditingController();
  bool register = false, busy = false, hide = true; String? error;
  late final AnimationController ambient = AnimationController(vsync:this,duration:const Duration(seconds:7))..forward();
  @override void dispose() { ambient.dispose(); username.dispose(); email.dispose(); password.dispose(); displayName.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() { busy = true; error = null; });
    try {
      if (register) {
        await widget.api.register(username: username.text.trim(), email: email.text.trim(), password: password.text, displayName: displayName.text.trim().isEmpty ? username.text.trim() : displayName.text.trim());
      } else { await widget.api.login(username.text.trim(), password.text); }
      widget.onDone();
    } on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Widget field(Widget child) => Padding(padding: const EdgeInsets.only(bottom:12),child: child);
  @override Widget build(BuildContext context) {
    final dark=Theme.of(context).brightness==Brightness.dark;
    final prefs=BinerPreferences.instance;
    return Scaffold(
      body: Stack(children:[
        Positioned.fill(child: AnimatedBuilder(animation:ambient,builder:(context,_)=>CustomPaint(painter:_AuthGlowPainter(ambient.value,dark)))),
        SafeArea(child: Center(child: SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,26,22,30),child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:440),
          child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const SizedBox(height:8),
            Center(child: Container(width:94,height:94,decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:LinearGradient(colors:[prefs.accent,const Color(0xFF7059FF)]),boxShadow:[BoxShadow(color:prefs.accent.withValues(alpha:.35),blurRadius:34,spreadRadius:2)]),child:const Icon(Icons.bolt_rounded,size:58,color:Color(0xFF06111D)))).animate().fadeIn(duration:500.ms).scale(begin:const Offset(.72,.72),curve:Curves.easeOutBack),
            const SizedBox(height:20),
            const Center(child:Brand()),
            const SizedBox(height:8),
            Text(register?binerText('یک حساب تازه، یک شروع تازه. ',en:'A fresh account. A fresh start.',ar:'حساب جديد وبداية جديدة.',tr:'Yeni hesap, yeni başlangıç.'):binerText('به دنیای BinerMention خوش آمدی',en:'Welcome to BinerMention',ar:'مرحباً بك في BinerMention',tr:'BinerMention dünyasına hoş geldin'),textAlign:TextAlign.center,style:TextStyle(color:dark?const Color(0xFFB6C5D9):const Color(0xFF65758B),fontSize:14)),
            const SizedBox(height:28),
            BinerLiquidGlass(borderRadius:BorderRadius.circular(30),padding:const EdgeInsets.fromLTRB(20,22,20,18),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Row(children:[
                Expanded(child:Text(register?binerText('ساخت حساب',en:'Create account',ar:'إنشاء حساب',tr:'Hesap oluştur'):binerText('ورود',en:'Sign in',ar:'تسجيل الدخول',tr:'Giriş yap'),style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900))),
                Container(padding:const EdgeInsets.all(4),decoration:BoxDecoration(color:prefs.accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(15)),child:Icon(Icons.shield_moon_rounded,color:prefs.accent)),
              ]),
              const SizedBox(height:6),
              Text(register?binerText('اطلاعاتت را وارد کن تا عضو شوی.',en:'Enter your details to join.',ar:'أدخل بياناتك للانضمام.',tr:'Katılmak için bilgilerini gir.'):binerText('برای ادامه وارد حساب خودت شو.',en:'Sign in to continue.',ar:'سجّل الدخول للمتابعة.',tr:'Devam etmek için giriş yap.'),style:const TextStyle(color:cMuted,fontSize:12)),
              const SizedBox(height:22),
              AnimatedSize(duration:const Duration(milliseconds:320),curve:Curves.easeInOutCubic,child:Column(children:[
                if(register) field(TextFormField(controller:displayName,decoration:InputDecoration(labelText:binerText('نام نمایشی',en:'Display name',ar:'الاسم الظاهر',tr:'Görünen ad'),prefixIcon:const Icon(Icons.badge_outlined)),validator:(v)=>v!=null&&v.length>80?binerText('حداکثر ۸۰ نویسه.',en:'Maximum 80 characters.'):null)),
                field(TextFormField(controller:username,autocorrect:false,decoration:InputDecoration(labelText:register?binerText('نام کاربری',en:'Username',ar:'اسم المستخدم',tr:'Kullanıcı adı'):binerText('نام کاربری یا ایمیل',en:'Username or email',ar:'اسم المستخدم أو البريد',tr:'Kullanıcı adı veya e-posta'),prefixIcon:const Icon(Icons.alternate_email_rounded)),validator:(v){if(v==null||v.trim().isEmpty)return binerText('این فیلد الزامی است.',en:'This field is required.',ar:'هذا الحقل مطلوب.',tr:'Bu alan zorunludur.');if(register&&!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(v.trim()))return binerText('نام کاربری ۳ تا ۲۴ نویسه باشد.',en:'Username must be 3–24 characters.',ar:'يجب أن يكون اسم المستخدم من 3 إلى 24 حرفاً.',tr:'Kullanıcı adı 3–24 karakter olmalı.');return null;})),
                if(register) field(TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:InputDecoration(labelText:binerText('ایمیل',en:'Email',ar:'البريد الإلكتروني',tr:'E-posta'),prefixIcon:const Icon(Icons.mail_outline_rounded)),validator:(v)=>v==null||!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())?binerText('ایمیل معتبر وارد کن.',en:'Enter a valid email.',ar:'أدخل بريداً إلكترونياً صالحاً.',tr:'Geçerli bir e-posta gir.'):null)),
                field(TextFormField(controller:password,obscureText:hide,decoration:InputDecoration(labelText:binerText('رمز عبور',en:'Password',ar:'كلمة المرور',tr:'Şifre'),prefixIcon:const Icon(Icons.lock_outline_rounded),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_rounded:Icons.visibility_off_rounded))),validator:(v)=>v==null||v.isEmpty?binerText('رمز عبور الزامی است.',en:'Password is required.',ar:'كلمة المرور مطلوبة.',tr:'Şifre gerekli.'):register&&v.length<10?binerText('حداقل ۱۰ نویسه وارد کن.',en:'Use at least 10 characters.',ar:'استخدم 10 أحرف على الأقل.',tr:'En az 10 karakter kullan.'):null,onFieldSubmitted:(_)=>submit())),
              ])),
              if(error!=null) Padding(padding:const EdgeInsets.only(bottom:12),child:Text(error!,style:const TextStyle(color:Colors.redAccent))),
              SizedBox(height:54,child:FilledButton(onPressed:busy?null:submit,style:FilledButton.styleFrom(backgroundColor:prefs.accent,foregroundColor:const Color(0xFF06111D),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),child:AnimatedSwitcher(duration:const Duration(milliseconds:180),child:busy?const SizedBox(key:ValueKey('busy'),width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Color(0xFF06111D))):Row(key:const ValueKey('label'),mainAxisAlignment:MainAxisAlignment.center,children:[Text(register?binerText('ثبت‌نام',en:'Create account',ar:'إنشاء حساب',tr:'Kaydol'):binerText('ورود امن',en:'Sign in securely',ar:'دخول آمن',tr:'Güvenli giriş'),style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(width:8),const Icon(Icons.arrow_forward_rounded,size:19)])))),
              const SizedBox(height:10),
              Center(child:TextButton(onPressed:busy?null:()=>setState(() { register = !register; error = null; }),child:Text(register?binerText('حساب داری؟ وارد شو',en:'Already have an account? Sign in',ar:'لديك حساب؟ سجّل الدخول',tr:'Hesabın var mı? Giriş yap'):binerText('حساب نداری؟ ثبت‌نام کن',en:'New here? Create an account',ar:'ليس لديك حساب؟ أنشئ حساباً',tr:'Yeni misin? Hesap oluştur')))),
            ]))),
            const SizedBox(height:18),
            Center(child:Wrap(alignment:WrapAlignment.center,spacing:8,children:[
              for(final item in const [('fa','فارسی'),('en','English'),('ar','العربية'),('tr','Türkçe')])
                ChoiceChip(label:Text(item.$2,style:const TextStyle(fontSize:11)),selected:prefs.locale.languageCode==item.$1,onSelected:busy?null:(_)=>prefs.setLanguage(item.$1),visualDensity:VisualDensity.compact),
            ])),
            const SizedBox(height:10),
            Center(child:Text('BINER / CONNECT WITHOUT LIMITS',style:TextStyle(color:cMuted.withValues(alpha:.7),fontSize:9,letterSpacing:2,fontWeight:FontWeight.w800))),
          ]).animate().fadeIn(duration:420.ms).slideY(begin:.035,duration:420.ms,curve:Curves.easeOutCubic),
        )))),
      ]),
    );
  }
}
class _AuthGlowPainter extends CustomPainter {
  const _AuthGlowPainter(this.phase,this.dark);
  final double phase; final bool dark;
  @override void paint(Canvas canvas,Size size){
    final p=Paint()..shader=RadialGradient(colors:[const Color(0xFF54C8FF).withValues(alpha:dark ? 0.18 : 0.12),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(size.width*(.15+.7*phase),size.height*.18),radius:size.width*.72));
    canvas.drawCircle(Offset(size.width*(.15+.7*phase),size.height*.18),size.width*.72,p);
    final v=Paint()..shader=RadialGradient(colors:[const Color(0xFF9B8CFF).withValues(alpha:dark ? 0.12 : 0.08),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(size.width*.08,size.height*.9),radius:size.width*.5));
    canvas.drawCircle(Offset(size.width*.08,size.height*.9),size.width*.5,v);
  }
  @override bool shouldRepaint(covariant _AuthGlowPainter old)=>old.phase!=phase||old.dark!=dark;
}


class _StoryViewer extends StatefulWidget {
  const _StoryViewer({required this.api, required this.stories, required this.initialIndex});
  final BinerApi api;
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  @override State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late final PageController _page = PageController(initialPage: widget.initialIndex);
  @override void dispose() { _page.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF05070B),
    body: PageView.builder(
      controller: _page,
      itemCount: widget.stories.length,
      itemBuilder: (context, index) => _StorySlide(
        key: ValueKey(widget.stories[index]['id']),
        api: widget.api,
        story: widget.stories[index],
        onClose: () => Navigator.maybePop(context),
      ),
    ),
  );
}

class _StorySlide extends StatefulWidget {
  const _StorySlide({super.key, required this.api, required this.story, required this.onClose});
  final BinerApi api;
  final Map<String, dynamic> story;
  final VoidCallback onClose;
  @override State<_StorySlide> createState() => _StorySlideState();
}

class _StorySlideState extends State<_StorySlide> {
  final _comment = TextEditingController();
  VideoPlayerController? _video;
  late bool _liked = widget.story['is_liked'] == true || widget.story['is_liked']?.toString() == '1';
  late int _likes = int.tryParse(widget.story['likes_count']?.toString() ?? '') ?? 0;
  late Future<List<Map<String, dynamic>>> _comments = widget.api.storyComments(int.parse(widget.story['id'].toString()));
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if ((widget.story['mime_type']?.toString() ?? '').startsWith('video/')) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.story['media_url'].toString()));
      _video = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        controller.setLooping(true);
        controller.play();
      }).catchError((_) {});
    }
  }

  @override
  void dispose() { _video?.dispose(); _comment.dispose(); super.dispose(); }

  Future<void> _toggleLike() async {
    final next = !_liked;
    setState(() { _liked = next; _likes = (_likes + (next ? 1 : -1)).clamp(0, 1 << 30); });
    try {
      await widget.api.toggleStoryLike(int.parse(widget.story['id'].toString()), next);
    } catch (_) {
      if (mounted) setState(() { _liked = !next; _likes = (_likes + (next ? -1 : 1)).clamp(0, 1 << 30); });
    }
  }

  Future<void> _sendComment() async {
    final body = _comment.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.addStoryComment(int.parse(widget.story['id'].toString()), body);
      _comment.clear();
      if (mounted) setState(() => _comments = widget.api.storyComments(int.parse(widget.story['id'].toString())));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showComments() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * .62,
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xF20B1422) : const Color(0xF7FFFFFF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: cLine),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .55), borderRadius: BorderRadius.circular(4))),
          const Padding(padding: EdgeInsets.all(18), child: Align(alignment: AlignmentDirectional.centerStart, child: Text('پاسخ‌های استوری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
          Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _comments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
              if (snapshot.hasError) return const Center(child: Text('دریافت دیدگاه‌ها انجام نشد.'));
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) return BinerEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'هنوز پاسخی ثبت نشده');
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                  title: Text(rows[i]['display_name']?.toString() ?? rows[i]['username']?.toString() ?? 'کاربر', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(rows[i]['body']?.toString() ?? ''),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final mime = widget.story['mime_type']?.toString() ?? '';
    final isVideo = mime.startsWith('video/');
    final name = widget.story['display_name']?.toString() ?? widget.story['username']?.toString() ?? 'استوری';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideo && video != null)
          Center(child: video.value.isInitialized
            ? GestureDetector(
                onTap: () => setState(() => video.value.isPlaying ? video.pause() : video.play()),
                child: AspectRatio(aspectRatio: video.value.aspectRatio > 0 ? video.value.aspectRatio : 9 / 16, child: VideoPlayer(video)),
              )
            : const CircularProgressIndicator(color: Colors.white))
        else
          Center(child: InteractiveViewer(
            minScale: .8, maxScale: 4,
            child: Image.network(widget.story['media_url']?.toString() ?? '', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 46)),
          )),
        const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Color(0xCC000000), Colors.transparent])))),
        const IgnorePointer(child: Align(alignment: Alignment.bottomCenter, child: SizedBox(height: 260, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xE6000000), Colors.transparent])))))),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              Expanded(child: Container(height: 3, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(3)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              const CircleAvatar(radius: 18, backgroundColor: Color(0x3354C8FF), child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              Text(widget.story['created_at']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 9)),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded, color: Colors.white)),
            ]),
          ),
          const Spacer(),
          if ((widget.story['caption']?.toString() ?? '').isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(widget.story['caption'].toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.5)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(children: [
              IconButton(onPressed: _toggleLike, icon: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _liked ? Colors.pinkAccent : Colors.white, size: 27)),
              Text('$_likes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              IconButton(onPressed: _showComments, icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white)),
              const Spacer(),
              SizedBox(width: 46, height: 46, child: IconButton.filledTonal(onPressed: () => video?.value.isPlaying == true ? video?.pause() : video?.play(), icon: Icon(video?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded))),
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 14),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _comment,
                  style: const TextStyle(color: Colors.white),
                  minLines: 1, maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'به این استوری پاسخ بده…',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true, fillColor: const Color(0xCC171B27),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                  ),
                )),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sending ? null : _sendComment, icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), style: IconButton.styleFrom(backgroundColor: cBlue, foregroundColor: const Color(0xFF071426))),
              ]),
            ),
          ),
        ])),
      ],
    );
  }
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
  final posts = <Map<String, dynamic>>[];
  final storyItems = <Map<String, dynamic>>[];
  final savedPosts = <Map<String, dynamic>>[];
  Map<String, dynamic>? me;
  String exploreQuery = '';
  bool showingSaved = false;
  Future<List<dynamic>>? exploreResults;
  final Set<String> _postActionsInFlight = <String>{};
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  @override void initState() { super.initState(); _notificationsFuture = widget.api.notifications(); _conversationsFuture = widget.api.conversations(); refresh(); loadProfile(); loadSavedPosts(); loadStories(); }
  Future<void> loadStories() async {
    try {
      final result = await widget.api.stories();
      if (mounted) setState(() { storyItems..clear()..addAll(result); });
    } on ApiException catch (e) { if (mounted) toast(e.message); }
  }

  Future<void> openOwnStories() async {
    final username = value(me ?? const <String, dynamic>{}, 'username');
    final mine = storyItems.where((item) => value(item, 'username') == username).toList();
    if (mine.isEmpty) { await createStory(); return; }
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: cLine),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .5), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 14),
          const Text('استوری‌های تو', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.play_circle_outline_rounded, color: cBlue), title: const Text('مشاهده استوری‌های من'), onTap: () => Navigator.pop(ctx, 'view')),
          ListTile(leading: const Icon(Icons.add_circle_outline_rounded, color: cBlue), title: const Text('افزودن استوری جدید'), onTap: () => Navigator.pop(ctx, 'add')),
        ]),
      ),
    );
    if (!mounted) return;
    if (action == 'view') await openStory(mine.first);
    if (action == 'add') await createStory();
  }

  Future<void> createStory() async {
    try {
      final file = await BinerMediaEditor.pickMedia();
      if (file == null || !mounted) return;
      toast('در حال بارگذاری استوری…');
      final uploaded = await widget.api.uploadMedia(file);
      final mediaId = int.tryParse(uploaded['id'].toString());
      if (mediaId == null) throw const ApiException('شناسه رسانه دریافت نشد.');
      await widget.api.createStory(mediaId);
      await loadStories();
      if (mounted) toast('استوری تا ۲۴ ساعت نمایش داده می‌شود.');
    } on ApiException catch (e) { if (mounted) toast(e.message); }
  }

  Future<void> openStory(Map<String,dynamic> story) async {
    final url = value(story,'media_url');
    if (!url.startsWith('https://')) return;
    if (!mounted) return;
    final index = storyItems.indexWhere((item) => value(item, 'id') == value(story, 'id'));
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _StoryViewer(api: widget.api, stories: List<Map<String, dynamic>>.unmodifiable(storyItems), initialIndex: index < 0 ? 0 : index),
    ));
  }

  Widget storyStrip() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(height: 112, child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        GestureDetector(onTap: openOwnStories, child: SizedBox(width: 76, child: Column(children: [
          Container(width: 58,height: 58,padding: const EdgeInsets.all(3),decoration: BoxDecoration(shape: BoxShape.circle,border: Border.all(color:cBlue,width:2)),child: CircleAvatar(backgroundColor: dark?const Color(0xFF15243A):const Color(0xFFEAF3FF),child: const Icon(Icons.add_rounded,color:cBlue,size:28))),
          const SizedBox(height:6),Text(binerText('استوری من',en:'Your story',ar:'قصتك',tr:'Hikayen'),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700)),
        ]))),
        ...storyItems.map((story) {
          final name=value(story,'display_name',value(story,'username','کاربر'));
          return GestureDetector(onTap:()=>openStory(story),child:SizedBox(width:76,child:Column(children:[
            Container(width:58,height:58,padding:const EdgeInsets.all(3),decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[cBlue,Color(0xFF9B8CFF),Color(0xFFFF78B8)])),child:CircleAvatar(backgroundColor:dark?const Color(0xFF111722):Colors.white,child:Icon(value(story,'mime_type').startsWith('video/')?Icons.play_arrow_rounded:Icons.photo_rounded,color:cBlue))),
            const SizedBox(height:6),Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600)),
          ])));
        }),
      ],
    ));
  }

  Future<void> loadSavedPosts() async {
    try {
      final remote = await widget.api.bookmarks();
      if (mounted) {
        setState(() { savedPosts..clear()..addAll(remote); });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('biner_saved_posts', remote.map((item) => jsonEncode(item)).toList());
      }
    } on ApiException {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getStringList('biner_saved_posts') ?? const <String>[];
      final restored = <Map<String, dynamic>>[];
      for (final item in encoded) {
        try { final decoded = jsonDecode(item); if (decoded is Map) restored.add(Map<String, dynamic>.from(decoded)); } catch (_) {}
      }
      if (mounted) setState(() { savedPosts..clear()..addAll(restored); });
    }
  }
  Future<void> toggleSavedPost(Map<String, dynamic> post) async {
    final id = int.tryParse(value(post, 'id'));
    if (id == null) return;
    final wasSaved = savedPosts.any((item) => value(item, 'id') == '$id');
    setState(() {
      if (wasSaved) { savedPosts.removeWhere((item) => value(item, 'id') == '$id'); }
      else { savedPosts.insert(0, Map<String, dynamic>.from(post)); }
    });
    try {
      await widget.api.toggleBookmark(id, !wasSaved);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('biner_saved_posts', savedPosts.map((item) => jsonEncode(item)).toList());
      if (mounted) toast(binerText('ذخیره‌ها به‌روزرسانی شد.', en:'Bookmarks updated.', ar:'تم تحديث المحفوظات.', tr:'Yer işaretleri güncellendi.'));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (wasSaved) { savedPosts.insert(0, Map<String, dynamic>.from(post)); }
          else { savedPosts.removeWhere((item) => value(item, 'id') == '$id'); }
        });
        toast(e.message);
      }
    }
  }
  Future<void> copyPost(Map<String, dynamic> post) async {
    final body = value(post, 'body');
    final username = value(post, 'username');
    await Clipboard.setData(ClipboardData(text: '@$username\n$body'));
    if (mounted) toast('متن پست کپی شد.');
  }
  void updateExploreQuery(String query) {
    setState(() {
      exploreQuery = query.trim();
      if (exploreQuery.isEmpty) {
        exploreResults = null;
      } else {
        final q = exploreQuery.replaceFirst(RegExp(r'^[#@]'), '');
        exploreResults = Future.wait<dynamic>([widget.api.searchUsers(q), widget.api.searchPosts(q)]);
      }
    });
  }
  Widget explore() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tags = <String, int>{};
    final pattern = RegExp(r'#[A-Za-z0-9_\u0600-\u06FF]{2,40}');
    for (final post in posts) {
      for (final match in pattern.allMatches(value(post, 'body'))) {
        final tag = match.group(0)!;
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }
    final trending = tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView(padding: const EdgeInsets.only(bottom: 20), children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 10), child: Row(children: [
        Expanded(child: Text(showingSaved ? binerText('پست‌های ذخیره‌شده',en:'Saved posts',ar:'المنشورات المحفوظة',tr:'Kaydedilen gönderiler') : binerText('کاوش و ترندها',en:'Explore & trends',ar:'استكشاف والاتجاهات',tr:'Keşfet ve gündem'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
        IconButton(tooltip: showingSaved ? binerText('نمایش کاوش',en:'Show Explore',ar:'عرض الاستكشاف',tr:'Keşfeti göster') : binerText('ذخیره‌ها',en:'Saved posts',ar:'المحفوظات',tr:'Kaydedilenler'), onPressed: () => setState(() { showingSaved = !showingSaved; exploreQuery = ''; exploreResults = null; }), icon: Icon(showingSaved ? Icons.explore_rounded : Icons.bookmarks_rounded, color: cBlue)),
      ])),
      if (!showingSaved) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
        onChanged: updateExploreQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: binerText('جست‌وجوی پست، هشتگ یا کاربر…',en:'Search posts, hashtags or people…',ar:'ابحث عن منشورات أو وسوم أو أشخاص…',tr:'Gönderi, etiket veya kişi ara…'),
          filled: true,
          fillColor: dark ? cGlass : const Color(0xF7FFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cLine)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cLine.withValues(alpha: .45))),
        ),
      )),
      if (showingSaved) ...[
        if (savedPosts.isEmpty) Padding(padding: const EdgeInsets.all(34), child: Center(child: Text(binerText('هنوز پستی ذخیره نکردی.',en:'You have no saved posts yet.',ar:'لا توجد منشورات محفوظة بعد.',tr:'Henüz kaydedilmiş gönderin yok.')))),
        ...savedPosts.map(card),
      ] else if (exploreQuery.isEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(18, 22, 18, 10), child: Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF8A4C)),
          const SizedBox(width: 8),
          Text(binerText('هشتگ‌های داغ',en:'Hot hashtags',ar:'الوسوم الرائجة',tr:'Popüler etiketler'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(binerText('از پست‌های بارگذاری‌شده',en:'From recent posts',ar:'من المنشورات الحديثة',tr:'Son gönderilerden'), style: TextStyle(color: cMuted, fontSize: 11)),
        ])),
        if (trending.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), child: Text(binerText('با انتشار پست‌های دارای هشتگ، این بخش پر می‌شود.',en:'Posts with hashtags will appear here.',ar:'ستظهر هنا المنشورات التي تحتوي على وسوم.',tr:'Etiket içeren gönderiler burada görünür.'), style: const TextStyle(color: cMuted)))
        else
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(
            spacing: 8, runSpacing: 8,
            children: trending.take(12).map((entry) => ActionChip(
              avatar: const Icon(Icons.tag_rounded, size: 17, color: cBlue),
              label: Text(entry.key),
              onPressed: () => updateExploreQuery(entry.key),
            )).toList(),
          )),
        Padding(padding: const EdgeInsets.fromLTRB(18, 24, 18, 8), child: Row(children: [
          Icon(Icons.bolt_rounded, color: cBlue),
          SizedBox(width: 8),
          Text(binerText('پست‌های پیشنهادی',en:'Suggested posts',ar:'منشورات مقترحة',tr:'Önerilen gönderiler'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ])),
        ...posts.map(card),
      ] else if (exploreResults != null)
        FutureBuilder<List<dynamic>>(
          future: exploreResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: cBlue)));
            if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(24), child: Text('${binerText('جست‌وجو انجام نشد',en:'Search failed',ar:'فشل البحث',tr:'Arama başarısız')}: ${snapshot.error}', textAlign: TextAlign.center));
            final users = snapshot.data != null && snapshot.data!.isNotEmpty ? snapshot.data![0] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];
            final foundPosts = snapshot.data != null && snapshot.data!.length > 1 ? snapshot.data![1] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (users.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 4), child: Text(binerText('آدم‌ها',en:'People',ar:'الأشخاص',tr:'Kişiler'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ...users.take(8).map((user) => ListTile(
                leading: avatar(value(user, 'display_name', value(user, 'username', 'کاربر')), user, 22),
                title: Text(value(user, 'display_name', value(user, 'username', 'کاربر'))),
                subtitle: Text('@${value(user, 'username')}', style: const TextStyle(color: cMuted)),
                trailing: const Icon(Icons.chevron_right_rounded, color: cBlue),
                onTap: () => openUserProfile(value(user, 'username')),
              )),
              if (foundPosts.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 4), child: Text(binerText('پست‌ها',en:'Posts',ar:'المنشورات',tr:'Gönderiler'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ...foundPosts.map(card),
              if (users.isEmpty && foundPosts.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(binerText('نتیجه‌ای پیدا نشد.',en:'No results found.',ar:'لم يتم العثور على نتائج.',tr:'Sonuç bulunamadı.')))),
            ]);
          },
        ),
    ]);
  }
  Future<void> loadProfile() async { try { final u = await widget.api.me(); if (mounted) setState(() => me = u); } on ApiException catch (e) { if (mounted) setState(() => error = e.message); } }
  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try { final data = await widget.api.posts(following: followingFeed); if (mounted) setState(() { posts..clear()..addAll(data); }); }
    on ApiException catch (e) { if (mounted) setState(() => error = e.message); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xF21A1A20), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cLine.withValues(alpha: .65))), margin: const EdgeInsets.fromLTRB(16, 0, 16, 12)));
  Future<void> openBinerAI() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BinerAIPage(api: widget.api)));
  }
  Future<void> openInsights() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InsightsPage(api: widget.api)));
  }
  Future<void> openGroupRooms() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupRoomsPage(api: widget.api)));
  }
  Future<void> openGroupInvite(String invite) async {
    try {
      final joined = await widget.api.joinGroup(invite);
      final id = int.tryParse(joined['group_id'].toString());
      final groups = await widget.api.groups();
      Map<String, dynamic>? group;
      for (final item in groups) { if (int.tryParse(item['id'].toString()) == id) { group = item; break; } }
      if (!mounted || id == null) return;
      if (group == null) { await openGroupRooms(); return; }
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupChatPage(api: widget.api, groupId: id, title: group!['title']?.toString() ?? 'گروه')));
    } on ApiException catch (e) { if (mounted) toast(e.message); }
  }


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
    final pattern = RegExp(r'bm:[a-fA-F0-9]{16}|#[A-Za-z0-9_\\u0600-\\u06FF]{2,40}|@[A-Za-z0-9_]{3,24}', caseSensitive: false);
    var cursor = 0;
    for (final match in pattern.allMatches(body)) {
      if (match.start > cursor) spans.add(TextSpan(text: body.substring(cursor, match.start)));
      final token = match.group(0)!;
      final isGroup = token.toLowerCase().startsWith('bm:');
      final isTag = token.startsWith('#');
      final value = isGroup ? token.substring(3) : token.substring(1);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => isGroup ? openGroupInvite(value) : isTag ? openHashtag(value) : openUserProfile(value),
          child: Text(token, style: TextStyle(color: isGroup ? cBlue : isTag ? const Color(0xFF35A7F5) : const Color(0xFF9B8CFF), fontWeight: FontWeight.w800, decoration: isGroup ? TextDecoration.underline : TextDecoration.none)),
        ),
      ));
      cursor = match.end;
    }
    if (cursor < body.length) spans.add(TextSpan(text: body.substring(cursor)));
    return RichText(text: TextSpan(style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.48, letterSpacing: .05), children: spans));
  }
  Future<void> compose({int? replyToId}) async {
    final controller = TextEditingController();
    final pollControllers = [TextEditingController(), TextEditingController()];
    bool pollEnabled = false;
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
              if (pollEnabled) ...[
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.poll_outlined, color: cBlue), const SizedBox(width: 8), Expanded(child: Text(binerText('گزینه‌های نظرسنجی',en:'Poll options',ar:'خيارات الاستطلاع',tr:'Anket seçenekleri'), style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(onPressed: () { if (pollControllers.length < 4) sheetSetState(() => pollControllers.add(TextEditingController())); }, icon: const Icon(Icons.add_circle_outline, color: cBlue))]),
                ...List.generate(pollControllers.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 6), child: TextField(controller: pollControllers[index], maxLength: 80, decoration: InputDecoration(counterText: '', hintText: binerText('گزینه ${index + 1}',en:'Option ${index + 1}',ar:'الخيار ${index + 1}',tr:'Seçenek ${index + 1}'), prefixIcon: const Icon(Icons.radio_button_unchecked, size: 18), suffixIcon: pollControllers.length > 2 ? IconButton(onPressed: () => sheetSetState(() { pollControllers.removeAt(index).dispose(); }), icon: const Icon(Icons.close, size: 18)) : null)))),
              ],
              if (attachment != null)
                ListTile(leading: const Icon(Icons.image, color: cBlue), title: Text(attachment!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => sheetSetState(() => attachment = null))),
              Row(children: [
                IconButton(tooltip: binerText('افزودن هشتگ',en:'Add hashtag',ar:'إضافة وسم',tr:'Etiket ekle'), onPressed: () => insertToken('#'), icon: const Icon(Icons.tag_rounded, color: cBlue)),
                IconButton(tooltip: binerText('منشن کردن کاربر',en:'Mention user',ar:'الإشارة إلى مستخدم',tr:'Kullanıcıdan bahset'), onPressed: () => insertToken('@'), icon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF9B8CFF))),
                IconButton(
                  tooltip: binerText('افزودن نظرسنجی',en:'Add a poll',ar:'إضافة استطلاع',tr:'Anket ekle'),
                  onPressed: () => sheetSetState(() => pollEnabled = !pollEnabled),
                  icon: Icon(Icons.poll_outlined, color: pollEnabled ? const Color(0xFF00BA7C) : cBlue),
                ),
                IconButton(
                  tooltip: binerText('افزودن عکس یا ویدیو',en:'Add photo or video',ar:'إضافة صورة أو فيديو',tr:'Fotoğraf veya video ekle'),
                  onPressed: () async {
                    final picked = await BinerMediaEditor.pickMedia();
                    if (picked != null) sheetSetState(() => attachment = picked);
                  },
                  icon: const Icon(Icons.image_outlined, color: cBlue),
                ),
                const Spacer(),
                FilledButton(onPressed: () => Navigator.pop(ctx, {'text': controller.text.trim(), 'attachment': attachment, 'poll_options': pollEnabled ? pollControllers.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList() : null}),
                    child: Text(binerText('انتشار',en:'Publish',ar:'نشر',tr:'Paylaş'))),
              ]),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    final pollOptions = (result?['poll_options'] as List?)?.whereType<String>().toList();
    for (final item in pollControllers) { item.dispose(); }
    if (result == null || !mounted) return;
    final text = (result['text'] as String? ?? '').trim();
    final file = result['attachment'] as XFile?;
    if (pollOptions != null && (pollOptions.length < 2 || pollOptions.length > 4)) { toast(binerText('نظرسنجی باید ۲ تا ۴ گزینه داشته باشد.',en:'A poll needs 2 to 4 options.',ar:'يجب أن يحتوي الاستطلاع على خيارين إلى أربعة.',tr:'Anket 2-4 seçenek içermeli.')); return; }
    if (text.isEmpty && file == null && (pollOptions == null || pollOptions.isEmpty)) return;
    setState(() => posting = true);
    try {
      int? mediaId;
      if (file != null) {
        final media = await widget.api.uploadMedia(file);
        mediaId = int.tryParse(media['id'].toString());
      }
      final item = replyToId == null
          ? await widget.api.createPost(text, mediaId: mediaId, pollOptions: pollOptions)
          : await widget.api.addComment(replyToId, text, mediaId: mediaId);
      if (replyToId == null && mounted) setState(() => posts.insert(0, item));
      if (replyToId != null && mounted) toast('کامنت ثبت شد.');
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
        title: Text(binerText('ویرایش پست',en:'Edit post',ar:'تعديل المنشور',tr:'Gönderiyi düzenle')),
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
        title: Text(binerText('حذف پست؟',en:'Delete post?',ar:'حذف المنشور؟',tr:'Gönderi silinsin mi?')),
        content: Text(binerText('این کار پست را از فید حذف می‌کند.',en:'This will remove the post from the feed.',ar:'سيؤدي هذا إلى إزالة المنشور من الموجز.',tr:'Bu işlem gönderiyi akıştan kaldırır.')),
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
        height: MediaQuery.of(ctx).size.height * .84,
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xF20B1422) : const Color(0xF7FFFFFF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: cLine),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .5), borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), child: Row(children: [
            const Expanded(child: Text('کامنت‌های این پست', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
            Text(fmt(post['replies_count'] ?? 0) + ' کامنت', style: const TextStyle(color: cMuted)),
          ])),
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .27),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(child: card(post)),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.api.comments(id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cBlue));
                if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(snap.error.toString(), textAlign: TextAlign.center)));
                final comments = snap.data ?? [];
                if (comments.isEmpty) return const Center(child: Text('هنوز کامنتی ثبت نشده؛ اولین نفر باش.', style: TextStyle(color: cMuted)));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => card(comments[i]),
                );
              },
            ),
          ),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () { Navigator.pop(ctx); compose(replyToId: id); },
              icon: const Icon(Icons.mode_comment_outlined),
              label: Text(binerText('نوشتن کامنت',en:'Write a comment',ar:'اكتب تعليقاً',tr:'Yorum yaz')),
            )),
          )),
        ]),
      ),
    );
  }

  Widget pollCard(Map<String, dynamic> p) {
    final poll = p['poll'];
    if (poll is! Map) return const SizedBox.shrink();
    final options = (poll['options'] as List? ?? const []).whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
    final total = int.tryParse((poll['total_votes'] ?? 0).toString()) ?? 0;
    final selected = int.tryParse((poll['my_vote_option_id'] ?? '').toString());
    final pollId = int.tryParse((poll['id'] ?? '').toString());
    return Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0x8839C5FF) : const Color(0xEEF1F7FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: cLine)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.poll_outlined, color: cBlue, size: 18), const SizedBox(width: 7), Text(binerText('نظرسنجی',en:'Poll',ar:'استطلاع',tr:'Anket'), style: const TextStyle(fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      ...options.map((option) { final id = int.tryParse((option['id'] ?? '').toString()); final votes = int.tryParse((option['votes_count'] ?? 0).toString()) ?? 0; final ratio = total == 0 ? 0.0 : votes / total; final chosen = selected != null && selected == id; return Padding(padding: const EdgeInsets.only(bottom: 7), child: InkWell(onTap: selected != null || id == null || pollId == null ? null : () async { try { final updated = await widget.api.votePoll(pollId, id); if (mounted) setState(() { p['poll'] = updated; }); } on ApiException catch (e) { if (mounted) toast(e.message); } }, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: chosen ? cBlue : cLine.withValues(alpha: .65))), child: Column(children: [Row(children: [Expanded(child: Text(option['option_text']?.toString() ?? '', style: TextStyle(fontWeight: chosen ? FontWeight.w800 : FontWeight.w500))), if (selected != null) Text('${(ratio * 100).round()}%', style: const TextStyle(color: cBlue, fontWeight: FontWeight.w800))]), if (selected != null) Padding(padding: const EdgeInsets.only(top: 7), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: cMuted.withValues(alpha: .18), color: chosen ? const Color(0xFF00BA7C) : cBlue))) ])))); }),
      Row(children: [Text('$total ${binerText('رأی',en:'votes',ar:'أصوات',tr:'oy')} ', style: const TextStyle(color: cMuted, fontSize: 12)), const Spacer(), Text(selected == null ? binerText('برای رأی دادن انتخاب کن',en:'Select an option to vote',ar:'اختر خيارًا للتصويت',tr:'Oy vermek için seç') : binerText('رأی ثبت شد',en:'Vote recorded',ar:'تم تسجيل التصويت',tr:'Oyun kaydedildi'), style: const TextStyle(color: cMuted, fontSize: 12))]),
    ]));
  }

  Widget card(Map<String, dynamic> p) {
    final name = value(p, 'display_name', value(p, 'username', 'کاربر'));
    final body = value(p, 'body');
    final liked = p['liked'] == true, reposted = p['reposted'] == true;
    final postCard = Container(padding: const EdgeInsets.fromLTRB(15, 15, 15, 11), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xCC101827) : const Color(0xF7FFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0x4439C5FF) : const Color(0x223D6592)), boxShadow: [BoxShadow(color: Theme.of(context).brightness == Brightness.dark ? const Color(0x16000000) : const Color(0x0D27476A), blurRadius: 22, offset: const Offset(0, 7))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(binerText('ویرایش پست',en:'Edit post',ar:'تعديل المنشور',tr:'Gönderiyi düzenle'))),
                const PopupMenuItem(value: 'delete', child: Text('حذف پست')),
              ],
            ),
        ]),
        if (body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8, right: 2), child: richPostBody(body)),
        pollCard(p),
        if (value(p, 'media_url').startsWith('https://'))
          Padding(padding: const EdgeInsets.only(top: 10), child: GestureDetector(
            onTap: () => BinerMediaViewer.open(context, url: value(p, 'media_url'), mimeType: value(p, 'mime_type'), title: '@${value(p, 'username')}'),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 520),
              child: (value(p, 'mime_type').startsWith('video/') || RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(value(p, 'media_url')))
                ? Container(width: double.infinity, height: 190, color: Colors.black, child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 52)))
                : Image.network(value(p, 'media_url'), width: double.infinity, fit: BoxFit.contain, cacheWidth: 1200, filterQuality: FilterQuality.low, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            )),
          )),
        const SizedBox(height: 10),
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 0, children: [
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 5)), onPressed: () => showReplies(p), icon: const Icon(Icons.chat_bubble_outline, size: 17), label: Text(fmt(p['replies_count'] ?? 0))),
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: reposted ? const Color(0xFF00BA7C) : cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 7)), onPressed: () => toggle(p, 'repost'), icon: const Icon(Icons.repeat, size: 17), label: Text(fmt(p['reposts_count'] ?? 0))),
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: liked ? const Color(0xFFF91880) : cMuted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 7)), onPressed: () => toggle(p, 'like'), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 17), label: Text(fmt(p['likes_count'] ?? 0))),
          IconButton(tooltip: savedPosts.any((item) => value(item, 'id') == value(p, 'id')) ? 'حذف از ذخیره‌ها' : 'ذخیره پست', visualDensity: VisualDensity.compact, onPressed: () => toggleSavedPost(p), icon: Icon(savedPosts.any((item) => value(item, 'id') == value(p, 'id')) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: savedPosts.any((item) => value(item, 'id') == value(p, 'id')) ? cBlue : cMuted, size: 20)),
          IconButton(tooltip: binerText('کپی متن پست',en:'Copy post text',ar:'نسخ نص المنشور',tr:'Gönderi metnini kopyala'), visualDensity: VisualDensity.compact, onPressed: () => copyPost(p), icon: const Icon(Icons.content_copy_rounded, color: cMuted, size: 18)),
        ]),
      ])),
    ]));
    return RepaintBoundary(child: BinerPreferences.instance.fastMode ? postCard : postCard.animate().fadeIn(duration: 220.ms).slideY(begin: .02, duration: 220.ms, curve: Curves.easeOutCubic));
  }
  Widget home() => Column(
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
        const Brand(), const Spacer(),
        IconButton(tooltip: 'BinerAI', onPressed: openBinerAI, icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B8CFF))),
        IconButton(tooltip: 'Biner Insights', onPressed: openInsights, icon: const Icon(Icons.insights_rounded, color: cBlue)),
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
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(binerText('برای تو', en:'For you', ar:'لك', tr:'Sana özel'), style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? cMuted : Theme.of(context).colorScheme.onSurface))),
            Container(height: 3, width: 82, decoration: BoxDecoration(color: followingFeed ? Colors.transparent : cBlue, borderRadius: BorderRadius.circular(3))),
          ]),
        )),
        Expanded(child: InkWell(
          onTap: () { if (!followingFeed) { setState(() => followingFeed = true); refresh(); } },
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(binerText('دنبال‌شونده‌ها', en:'Following', ar:'المتابَعون', tr:'Takip edilenler'), style: TextStyle(fontWeight: FontWeight.bold, color: followingFeed ? Theme.of(context).colorScheme.onSurface : cMuted))),
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
              OutlinedButton(onPressed: refresh, child: Text(binerText('تلاش دوباره',en:'Try again',ar:'حاول مرة أخرى',tr:'Tekrar dene'))),
            ],
          ),
        ),
      );
    }
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(children: [
          storyStrip(),
          const SizedBox(height: 70),
          Center(child: Text('هنوز پستی وجود ندارد.')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: posts.length + 1,
        itemBuilder: (context, index) => index == 0 ? storyStrip() : card(posts[index - 1]),
      ),
    );
  }

  Widget notifications() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _notificationsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ListView(children: [BinerSkeleton(lines: 1), BinerSkeleton(lines: 1), BinerSkeleton(lines: 1)]);
      }
      if (snapshot.hasError) {
        return BinerEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'اعلان‌ها بارگذاری نشدند',
          description: 'اتصال به سرور را بررسی کن و دوباره وارد این بخش شو.',
        );
      }
      final items = snapshot.data ?? const <Map<String, dynamic>>[];
      if (items.isEmpty) {
        return const BinerEmptyState(icon: Icons.notifications_none_rounded, title: 'اعلان تازه‌ای نداری', description: 'وقتی کسی با پست یا حساب تو تعامل کند، اینجا می‌بینی.');
      }
      final labels = <String, String>{
        'mention': 'در یک پست منشن‌ات کرد',
        'follow': 'دنبال‌ات کرد',
        'like': 'پستت را پسندید',
        'repost': 'پستت را بازنشر کرد',
        'reply': 'به پستت پاسخ داد',
        'message': 'پیام فرستاد',
        'story_like': 'استوری‌ات را پسندید',
      };
      final icons = <String, IconData>{
        'mention': Icons.alternate_email_rounded,
        'follow': Icons.person_add_alt_1_rounded,
        'like': Icons.favorite_rounded,
        'repost': Icons.repeat_rounded,
        'reply': Icons.mode_comment_outlined,
        'message': Icons.mail_outline_rounded,
        'story_like': Icons.auto_awesome_rounded,
      };
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return BinerSectionHeader(title: 'اعلان‌ها', subtitle: 'آخرین اتفاق‌های مربوط به حساب تو');
          final item = items[index - 1];
          final kind = value(item, 'type');
          final name = value(item, 'actor_display_name', value(item, 'actor_username', 'کاربر'));
          return BinerSurfaceCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            radius: 18,
            child: Row(children: [
              avatar(name, {'avatar_url': value(item, 'actor_avatar_url')}, 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 3),
                Text(labels[kind] ?? 'تعامل جدید', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value(item, 'created_at'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7), fontSize: 9)),
              ])),
              Container(width: 34, height: 34, decoration: BoxDecoration(color: cBlue.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icons[kind] ?? Icons.notifications_active_outlined, color: cBlue, size: 18)),
            ]),
          );
        },
      );
    },
  );

  Future<void> startConversation() async {
    final controller = TextEditingController();
    final username = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(binerText('پیام جدید',en:'New message',ar:'رسالة جديدة',tr:'Yeni mesaj')),
      content: TextField(controller: controller, autocorrect: false, decoration: InputDecoration(labelText: binerText('نام کاربری گیرنده',en:'Recipient username',ar:'اسم المستخدم للمستلم',tr:'Alıcının kullanıcı adı'))),
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
    future: _conversationsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ListView(children: [BinerSkeleton(lines: 1), BinerSkeleton(lines: 1), BinerSkeleton(lines: 1)]);
      }
      if (snapshot.hasError) {
        return BinerEmptyState(icon: Icons.cloud_off_rounded, title: 'پیام‌ها بارگذاری نشدند', description: 'وضعیت اتصال و API را بررسی کن.');
      }
      final items = snapshot.data ?? const <Map<String, dynamic>>[];
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        itemCount: items.isEmpty ? 2 : items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BinerSectionHeader(
                title: 'پیام‌ها',
                subtitle: 'گفتگوهای خصوصی و اتاق‌های گروهی',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'اتاق‌های گفتگو', onPressed: openGroupRooms, icon: const Icon(Icons.groups_rounded)),
                  IconButton(tooltip: 'پیام جدید', onPressed: startConversation, icon: const Icon(Icons.edit_square)),
                ]),
              ),
            );
          }
          if (items.isEmpty) {
            return const BinerEmptyState(icon: Icons.forum_outlined, title: 'هنوز گفتگویی نداری', description: 'برای شروع یک پیام تازه بساز یا وارد اتاق گفتگو شو.');
          }
          final conversation = items[index - 1];
          final display = value(conversation, 'other_display_name', value(conversation, 'other_username', 'گفتگو'));
          final username = value(conversation, 'other_username');
          final person = <String, dynamic>{'avatar_url': value(conversation, 'other_avatar_url'), 'username': username};
          return BinerSurfaceCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            radius: 19,
            onTap: () async {
              final id = int.tryParse(value(conversation, 'id'));
              if (id == null) return;
              try {
                final currentUser = me ?? await widget.api.me();
                if (!mounted) return;
                setState(() => me = currentUser);
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatPage(
                  api: widget.api,
                  conversationId: id,
                  currentUserId: int.parse(currentUser['id'].toString()),
                  title: display,
                )));
              } on ApiException catch (e) {
                if (mounted) toast(e.message);
              }
              if (mounted) setState(() {});
            },
            child: Row(children: [
              avatar(display, person, 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(display, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  (username.isNotEmpty ? '@$username · ' : '') + value(conversation, 'last_message', 'گفتگوی تازه'),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                ),
              ])),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ]),
          );
        },
      );
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
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: cLine),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .5), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(binerText('کشف آدم‌های جدید',en:'Discover people',ar:'اكتشف أشخاصاً جدد',tr:'Yeni kişileri keşfet'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                filled: true, fillColor: Theme.of(ctx).inputDecorationTheme.fillColor,
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
    final u = me;
    if (u == null) return const Center(child: BinerSkeleton(lines: 3));
    final display = value(u, 'display_name', value(u, 'username', 'کاربر'));
    final username = value(u, 'username'), bio = value(u, 'bio'), website = value(u, 'website');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
      BinerLiquidGlass(borderRadius: BorderRadius.circular(30), padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 118, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF101018), Color(0xFF101F35), Color(0xFF17102B)]), border: Border.all(color: cLine.withValues(alpha: .6))),
            child: Stack(children: [
              Positioned(right: 18, top: 12, child: Icon(Icons.blur_on_rounded, size: 84, color: cBlue.withValues(alpha: .16))),
              Positioned(left: 18, bottom: 10, child: Text('BINER / IDENTITY', style: TextStyle(color: cBlue.withValues(alpha: .75), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800))),
              const Center(child: Icon(Icons.bolt_rounded, color: cBlue, size: 54)),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            avatar(display, u, 34), const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))), blueTick(u)]),
              const SizedBox(height: 3), Text('@$username', style: const TextStyle(color: cMuted, fontSize: 13)),
            ])),
            IconButton(tooltip: 'ویرایش پروفایل', onPressed: () => editProfile(u), icon: const Icon(Icons.edit_rounded, color: cBlue)),
          ]),
          if (bio.isNotEmpty) ...[const SizedBox(height: 16), Text(bio, style: const TextStyle(fontSize: 14, height: 1.7))],
          if (website.isNotEmpty) ...[const SizedBox(height: 10), Row(children: [const Icon(Icons.link_rounded, color: cBlue, size: 18), const SizedBox(width: 8), Expanded(child: Text(website, style: const TextStyle(color: cBlue), maxLines: 2, overflow: TextOverflow.ellipsis))])],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _profileMetric('پست‌ها', value(u, 'posts_count', '0'))), const SizedBox(width: 8),
            Expanded(child: _profileMetric('دنبال‌کننده', value(u, 'followers_count', '0'))), const SizedBox(width: 8),
            Expanded(child: _profileMetric('دنبال‌شونده', value(u, 'following_count', '0'))),
          ]),
        ]),
      ).animate().fadeIn(duration: 320.ms).slideY(begin: .025, duration: 320.ms, curve: Curves.easeOutCubic),
      const SizedBox(height: 14),
      BinerLiquidGlass(borderRadius: BorderRadius.circular(22), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          ListTile(leading: const Icon(Icons.tune_rounded, color: cBlue), title: Text(binerText('شخصی‌سازی پروفایل',en:'Customize profile',ar:'تخصيص الملف الشخصي',tr:'Profili özelleştir')), subtitle: const Text('نام، تصویر، بیو و لینک‌ها'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => editProfile(u)),
          Divider(height: 1, color: cLine.withValues(alpha: .35)),
          ListTile(leading: const Icon(Icons.shield_outlined, color: cBlue), title: Text(binerText('حریم خصوصی و امنیت',en:'Privacy & security',ar:'الخصوصية والأمان',tr:'Gizlilik ve güvenlik')), subtitle: Text(binerText('تنظیمات حساب و محافظت از آن',en:'Account settings and protection',ar:'إعدادات الحساب وحمايته',tr:'Hesap ayarları ve koruması')), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => toast('تنظیمات امنیتی در حال آماده‌سازی است.')),
          Divider(height: 1, color: cLine.withValues(alpha: .35)),
          ListTile(leading: const Icon(Icons.palette_outlined, color: cBlue), title: Text(binerText('زبان، رنگ و عملکرد', en:'Language, color & performance', ar:'اللغة واللون والأداء', tr:'Dil, renk ve performans')), subtitle: Text(binerText('فارسی، انگلیسی، عربی، ترکی و حالت سریع', en:'Persian, English, Arabic, Turkish and fast mode', ar:'الفارسية والإنجليزية والعربية والتركية والوضع السريع', tr:'Farsça, İngilizce, Arapça, Türkçe ve hızlı mod')), trailing: const Icon(Icons.chevron_right_rounded), onTap: openAppSettings),
          Divider(height: 1, color: cLine.withValues(alpha: .35)),
          ListTile(leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF7185)), title: Text(binerText('خروج از حساب',en:'Sign out',ar:'تسجيل الخروج',tr:'Çıkış yap')), subtitle: Text(binerText('پایان نشست فعلی',en:'End current session',ar:'إنهاء الجلسة الحالية',tr:'Geçerli oturumu kapat')), onTap: () async => widget.logout()),
        ]),
      ),
    ]);
  }

  Future<void> openAppSettings() async {
    final prefs = BinerPreferences.instance;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: prefs,
        builder: (ctx, _) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .9),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xF20B1422) : const Color(0xF7FFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: prefs.accent.withValues(alpha: .38)),
          ),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .6), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Text(binerText('تنظیمات ظاهری و عملکرد', en:'Appearance & performance', ar:'المظهر والأداء', tr:'Görünüm ve performans'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(binerText('زبان برنامه', en:'App language', ar:'لغة التطبيق', tr:'Uygulama dili'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [('fa','فارسی'),('en','English'),('ar','العربية'),('tr','Türkçe')])
                ChoiceChip(label: Text(item.$2), selected: prefs.locale.languageCode == item.$1, onSelected: (_) => prefs.setLanguage(item.$1)),
            ]),
            const SizedBox(height: 16),
            Text(binerText('فونت برنامه', en:'App font', ar:'خط التطبيق', tr:'Uygulama yazı tipi'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [('system','فونت گوشی'),('vazir','وزیرمتن'),('noto','فونت اصلی')])
                ChoiceChip(label: Text(item.$2), selected: prefs.fontFamily == item.$1, onSelected: (_) => prefs.setFontFamily(item.$1)),
            ]),
            const SizedBox(height: 16),
            Text(binerText('رنگ اصلی', en:'Accent color', ar:'اللون الأساسي', tr:'Vurgu rengi'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Wrap(spacing: 13, children: [
              for (final color in const [Color(0xFF54C8FF),Color(0xFF8B7CFF),Color(0xFF36D6A0),Color(0xFFFF8A65),Color(0xFFFF6FAE),Color(0xFFFFC857)])
                GestureDetector(onTap: () => prefs.setAccent(color), child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: prefs.accent.toARGB32() == color.toARGB32() ? Theme.of(ctx).colorScheme.onSurface : Colors.transparent, width: 3), boxShadow: [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 10)]), child: prefs.accent.toARGB32() == color.toARGB32() ? const Icon(Icons.check_rounded, size: 18, color: Colors.black) : null)),
            ]),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero, value: prefs.fastMode,
              onChanged: prefs.setFastMode,
              secondary: const Icon(Icons.speed_rounded, color: cBlue),
              title: Text(binerText('حالت سریع برای گوشی‌های ضعیف', en:'Fast mode for low-end phones', ar:'الوضع السريع للهواتف الضعيفة', tr:'Düşük donanımlı telefonlar için hızlı mod')),
              subtitle: Text(binerText('کاهش افکت‌های سنگین و محوشدگی برای روان‌تر شدن برنامه', en:'Reduce heavy effects and blur for smoother performance', ar:'تقليل المؤثرات الثقيلة والضبابية لتحسين الأداء', tr:'Daha akıcı kullanım için ağır efektleri ve bulanıklığı azaltır')),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _profileMetric(String label, String count) => BinerSurfaceCard(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    radius: 16,
    child: Column(children: [
      Text(count, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );

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
          title: Text(binerText('شخصی‌سازی پروفایل',en:'Customize profile',ar:'تخصيص الملف الشخصي',tr:'Profili özelleştir')),
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
                final picked = await BinerMediaEditor.pickImage();
                if (picked != null) dialogSetState(() => avatarFile = picked);
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(avatarFile == null ? 'انتخاب عکس پروفایل' : 'تغییر عکس انتخاب‌شده'),
            ),
            TextField(controller: name, maxLength: 80, decoration: InputDecoration(labelText: binerText('نام نمایشی',en:'Display name',ar:'الاسم الظاهر',tr:'Görünen ad'), prefixIcon: Icon(Icons.badge_outlined))),
            TextField(controller: bio, maxLength: 280, maxLines: 3, decoration: InputDecoration(labelText: binerText('بیوگرافی',en:'Bio',ar:'نبذة',tr:'Biyografi'), prefixIcon: Icon(Icons.edit_note))),
            TextField(controller: website, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: binerText('وب‌سایت یا لینک شخصی',en:'Website or personal link',ar:'الموقع أو رابط شخصي',tr:'Web sitesi veya kişisel bağlantı'), prefixIcon: Icon(Icons.link))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(binerText('ذخیره تغییرات',en:'Save changes',ar:'حفظ التغييرات',tr:'Değişiklikleri kaydet'))),
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

  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: BinerPreferences.instance,
    builder: (context, _) {
      final pages = [home(), explore(), notifications(), conversations(), profile()];
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: BinerLiquidGlass(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: cBlue.withValues(alpha: .20),
            selectedIndex: tab,
            onDestinationSelected: (i) { setState(() { tab = i; if (i == 2) _notificationsFuture = widget.api.notifications(); if (i == 3) _conversationsFuture = widget.api.conversations(); }); },
            destinations: [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: cBlue), label: binerText('خانه', en:'Home', ar:'الرئيسية', tr:'Ana sayfa')),
              NavigationDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.search_rounded, color: cBlue), label: binerText('کاوش', en:'Explore', ar:'استكشاف', tr:'Keşfet')),
              NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded, color: cBlue), label: binerText('اعلان‌ها',en:'Notifications',ar:'الإشعارات',tr:'Bildirimler')),
              NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded, color: cBlue), label: binerText('پیام‌ها', en:'Messages', ar:'الرسائل', tr:'Mesajlar')),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: cBlue), label: binerText('پروفایل', en:'Profile', ar:'الملف الشخصي', tr:'Profil')),
            ],
          ),
        ),
      ),
      );
    },
  );
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
  String value(Map<String, dynamic> m, String k, [String fallback = '']) => m[k]?.toString() ?? fallback;

  Widget messageBody(String body) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'bm:[a-fA-F0-9]{16}', caseSensitive: false);
    var cursor = 0;
    for (final match in pattern.allMatches(body)) {
      if (match.start > cursor) spans.add(TextSpan(text: body.substring(cursor, match.start)));
      final token = match.group(0)!;
      final code = token.substring(3);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () async {
            try {
              final joined = await widget.api.joinGroup(code);
              final id = int.tryParse(joined['group_id'].toString());
              final groups = await widget.api.groups();
              Map<String, dynamic>? group;
              for (final item in groups) {
                if (int.tryParse(item['id'].toString()) == id) { group = item; break; }
              }
              if (!mounted || id == null) return;
              if (group == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('به گروه اضافه شدی.')));
                return;
              }
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => GroupChatPage(api: widget.api, groupId: id, title: group!['title']?.toString() ?? 'گروه'),
              ));
            } on ApiException catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
          child: Text(token, style: const TextStyle(color: cBlue, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
        ),
      ));
      cursor = match.end;
    }
    if (cursor < body.length) spans.add(TextSpan(text: body.substring(cursor)));
    return RichText(text: TextSpan(style: const TextStyle(fontSize: 15, height: 1.42), children: spans));
  }
  void toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))));
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

  Future<void> send({XFile? attachment}) async {
    final raw = controller.text.trim();
    if ((raw.isEmpty && attachment == null) || sending) return;
    final reply = replyingTo;
    final text = reply == null ? raw : '↪ پاسخ به ${reply['sender_name'] ?? 'کاربر'}: "${(reply['body'] ?? '').toString().replaceAll('\n', ' ')}"\n$raw';
    controller.clear();
    FocusScope.of(context).unfocus();
    setState(() => replyingTo = null);
    setState(() => sending = true);
    try {
      int? mediaId;
      if (attachment != null) {
        final uploaded = await widget.api.uploadMedia(attachment);
        mediaId = int.tryParse(uploaded['id'].toString());
        if (mediaId == null) throw const ApiException('شناسه فایل از سرور دریافت نشد.');
      }
      final item = await widget.api.sendMessage(widget.conversationId, text, mediaId: mediaId);
      if (!mounted) return;
      setState(() => items.add(item));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      });
    } on ApiException catch (e) {
      if (mounted) { controller.text = raw; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))); }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> handleChatSafetyAction(String action) async {
    if (action == 'report') {
      final reasonController = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(binerText('گزارش گفت‌وگو',en:'Report conversation',ar:'الإبلاغ عن المحادثة',tr:'Sohbeti bildir')),
          content: TextField(controller: reasonController, maxLength: 500, maxLines: 3, decoration: const InputDecoration(hintText: 'دلیل گزارش را بنویس…')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, reasonController.text.trim().isEmpty ? 'محتوای نامناسب' : reasonController.text.trim()), child: Text(binerText('ارسال گزارش',en:'Submit report',ar:'إرسال البلاغ',tr:'Bildirimi gönder'))),
          ],
        ),
      );
      reasonController.dispose();
      if (reason == null || !mounted) return;
      try {
        await widget.api.reportConversation(widget.conversationId, reason);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گزارش ثبت شد. ممنون که اطلاع دادی.')));
      } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } else if (action == 'block') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(binerText('مسدود کردن کاربر؟',en:'Block user?',ar:'حظر المستخدم؟',tr:'Kullanıcı engellensin mi?')),
          content: const Text('پس از مسدودسازی، ارسال پیام در این گفت‌وگو متوقف می‌شود.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(binerText('مسدود کن',en:'Block',ar:'حظر',tr:'Engelle'))),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await widget.api.blockConversationUser(widget.conversationId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کاربر مسدود شد.')));
      } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    }
  }

  Future<void> showTextTool(String source, {required bool translate}) async {
    if (source.trim().isEmpty) { toast('متنی برای پردازش وجود ندارد.'); return; }
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: cBlue)));
    try {
      final result = translate ? await BinerTextTools.translate(source, BinerPreferences.instance.locale.languageCode) : BinerTextTools.summarize(source);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: Text(translate ? binerText(binerText('ترجمه پیام',en:'Translate message',ar:'ترجمة الرسالة',tr:'Mesajı çevir'),en:'Message translation',ar:'ترجمة الرسالة',tr:'Mesaj çevirisi') : binerText('خلاصه پیام',en:'Message summary',ar:'ملخص الرسالة',tr:'Mesaj özeti')),
        content: SelectableText(result),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(binerText('بستن',en:'Close',ar:'إغلاق',tr:'Kapat')))],
      ));
    } catch (e) {
      if (mounted) { Navigator.of(context, rootNavigator: true).pop(); toast('پردازش متن انجام نشد: $e'); }
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
              ListTile(leading: const Icon(Icons.reply_rounded, color: cBlue), title: Text(binerText('پاسخ به پیام',en:'Reply to message',ar:'الرد على الرسالة',tr:'Mesajı yanıtla')), subtitle: Text((item['body'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => Navigator.pop(ctx, 'reply')),
              ListTile(leading: const Icon(Icons.forward_rounded, color: Color(0xFF9B8CFF)), title: Text(binerText('بازارسال به گفت‌وگوی دیگر',en:'Forward to another chat',ar:'إعادة التوجيه إلى محادثة أخرى',tr:'Başka sohbete ilet')), subtitle: const Text('انتخاب مقصد'), onTap: () => Navigator.pop(ctx, 'forward')),
              ListTile(leading: const Icon(Icons.copy_rounded, color: cMuted), title: Text(binerText('کپی متن پیام',en:'Copy message text',ar:'نسخ نص الرسالة',tr:'Mesaj metnini kopyala')), onTap: () => Navigator.pop(ctx, 'copy')),
               ListTile(leading: const Icon(Icons.summarize_rounded, color: cBlue), title: Text(binerText('خلاصه‌سازی پیام',en:'Summarize message',ar:'تلخيص الرسالة',tr:'Mesajı özetle')), onTap: () => Navigator.pop(ctx, 'summary')),
               ListTile(leading: const Icon(Icons.translate_rounded, color: Color(0xFF9B8CFF)), title: Text(binerText('ترجمه پیام',en:'Translate message',ar:'ترجمة الرسالة',tr:'Mesajı çevir')), onTap: () => Navigator.pop(ctx, 'translate')),
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
    } else if (action == 'summary') {
      await showTextTool(body, translate: false);
    } else if (action == 'translate') {
      await showTextTool(body, translate: true);
    } else if (action == 'forward') {
      try {
        final conversations = await widget.api.conversations();
        if (!mounted) return;
        final destinations = conversations.where((c) => int.tryParse(value(c, 'id')) != widget.conversationId).toList();
        if (destinations.isEmpty) {
          toast('برای بازارسال، ابتدا یک گفت‌وگوی دیگر بساز.');
          return;
        }
        final destinationId = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (ctx) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xF20B0B10), borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), border: Border.all(color: cLine)),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: cMuted.withValues(alpha: .55), borderRadius: BorderRadius.circular(4))),
                  const Padding(padding: EdgeInsets.all(14), child: Text('انتخاب مقصد بازارسال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .55), child: ListView(
                    shrinkWrap: true,
                    children: destinations.map((c) {
                      final id = int.tryParse(value(c, 'id'));
                      final name = value(c, 'other_display_name', value(c, 'other_username', 'گفت‌وگو'));
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0x2239C5FF), child: Icon(Icons.person_rounded, color: cBlue)),
                        title: Text(name),
                        subtitle: Text(value(c, 'last_message', binerText('گفت‌وگوی جدید',en:'New conversation',ar:'محادثة جديدة',tr:'Yeni sohbet')), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_rounded, color: cBlue),
                        onTap: id == null ? null : () => Navigator.pop(ctx, id),
                      );
                    }).toList(),
                  )),
                ]),
              ),
            ),
          ),
        );
        if (destinationId == null || !mounted) return;
        await widget.api.sendMessage(destinationId, '↗ بازارسال‌شده\n$body');
        if (mounted) toast('پیام بازارسال شد.');
      } on ApiException catch (e) {
        if (mounted) toast(e.message);
      }
    }
  }

  Widget messageList() {
    if (loading && items.isEmpty) {
      return ListView(children: const [BinerSkeleton(lines: 2), BinerSkeleton(lines: 2), BinerSkeleton(lines: 2)]);
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
              OutlinedButton(onPressed: loadMessages, child: Text(binerText('تلاش دوباره',en:'Try again',ar:'حاول مرة أخرى',tr:'Tekrar dene'))),
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
                if ((item['media_url']?.toString() ?? '').startsWith('https://')) ...[
                  GestureDetector(
                    onTap: () => BinerMediaViewer.open(
                      context,
                      url: item['media_url'].toString(),
                      mimeType: item['mime_type']?.toString(),
                      title: widget.title,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ((item['mime_type']?.toString().startsWith('video/') ?? false) ||
                              RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(item['media_url'].toString()))
                          ? Container(
                              width: 210,
                              height: 126,
                              color: Colors.black,
                              child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48)),
                            )
                          : Image.network(
                              item['media_url'].toString(),
                              width: 210,
                              height: 170,
                              fit: BoxFit.cover,
                              cacheWidth: 630,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                if ((item['body']?.toString() ?? '').isNotEmpty) messageBody(item['body']?.toString() ?? ''),
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BinerPreferences.instance,
    builder: (context, _) => _buildChat(),
  );

  Widget _buildChat() => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: cBlue.withValues(alpha: .12), border: Border.all(color: cLine)), child: const Icon(Icons.person_rounded, color: cBlue, size: 20)), const SizedBox(width: 10), Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)))]),
      actions: [
        IconButton(tooltip: 'BinerAI', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BinerAIPage(api: widget.api))), icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B8CFF))),
        IconButton(tooltip: binerText('بارگذاری دوباره',en:'Refresh',ar:'تحديث',tr:'Yenile'), onPressed: loadMessages, icon: const Icon(Icons.refresh_rounded)),
        PopupMenuButton<String>(tooltip: binerText('گزینه‌های گفت‌وگو',en:'Chat options',ar:'خيارات المحادثة',tr:'Sohbet seçenekleri'), onSelected: handleChatSafetyAction, itemBuilder: (_) => const [
          PopupMenuItem(value: 'report', child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.flag_outlined), title: Text('گزارش گفت‌وگو'))),
          PopupMenuItem(value: 'block', child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.block_rounded, color: Color(0xFFFF7185)), title: Text('مسدود کردن کاربر'))),
        ]),
      ],
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
                IconButton(
                  tooltip: binerText('ارسال عکس یا ویدیو',en:'Send photo or video',ar:'إرسال صورة أو فيديو',tr:'Fotoğraf veya video gönder'),
                  onPressed: sending ? null : () async {
                    final picked = await BinerMediaEditor.pickMedia();
                    if (picked != null && mounted) await send(attachment: picked);
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: cBlue),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: binerText('پیامت را بنویس...', en:'Write a message...', ar:'اكتب رسالة...', tr:'Mesaj yaz...'),
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
