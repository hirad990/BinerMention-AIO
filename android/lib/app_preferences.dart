import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BinerPreferences extends ChangeNotifier {
  BinerPreferences._();
  static final BinerPreferences instance = BinerPreferences._();
  Locale locale = const Locale('fa');
  Color accent = const Color(0xFF54C8FF);
  bool fastMode = false;
  String fontFamily = 'noto';
  bool ready = false;
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final language = p.getString('biner_language') ?? 'fa';
    locale = Locale(['fa','en','ar','tr'].contains(language) ? language : 'fa');
    accent = Color(p.getInt('biner_accent') ?? 0xFF54C8FF);
    fastMode = p.getBool('biner_fast_mode') ?? false;
    fontFamily = ['system','vazir','noto'].contains(p.getString('biner_font_family')) ? p.getString('biner_font_family')! : 'noto';
    ready = true; notifyListeners();
  }
  Future<void> setLanguage(String code) async {
    if (!['fa','en','ar','tr'].contains(code)) return;
    locale = Locale(code); final p = await SharedPreferences.getInstance();
    await p.setString('biner_language', code); notifyListeners();
  }
  Future<void> setAccent(Color color) async {
    accent = color; final p = await SharedPreferences.getInstance();
    await p.setInt('biner_accent', color.toARGB32()); notifyListeners();
  }
  Future<void> setFontFamily(String family) async {
    if (!['system','vazir','noto'].contains(family)) return;
    fontFamily = family;
    final p = await SharedPreferences.getInstance();
    await p.setString('biner_font_family', family);
    notifyListeners();
  }
  Future<void> setFastMode(bool enabled) async {
    fastMode = enabled; final p = await SharedPreferences.getInstance();
    await p.setBool('biner_fast_mode', enabled); notifyListeners();
  }
  TextDirection get direction => locale.languageCode == 'fa' || locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
}
const Map<String, Map<String, String>> _binerTranslations = {
  'پاسخ‌های استوری': {'en':'Story replies','ar':'ردود القصص','tr':'Hikâye yanıtları'},
  'دریافت دیدگاه‌ها انجام نشد.': {'en':'Could not load replies.','ar':'تعذر تحميل الردود.','tr':'Yanıtlar yüklenemedi.'},
  'هنوز پاسخی ثبت نشده': {'en':'No replies yet','ar':'لا توجد ردود بعد','tr':'Henüz yanıt yok'},
  'به این استوری پاسخ بده…': {'en':'Reply to this story…','ar':'رد على هذه القصة…','tr':'Bu hikâyeye yanıt ver…'},
  'استوری‌های تو': {'en':'Your stories','ar':'قصصك','tr':'Hikâyelerin'},
  'مشاهده استوری‌های من': {'en':'View my stories','ar':'عرض قصصي','tr':'Hikâyelerimi görüntüle'},
  'افزودن استوری جدید': {'en':'Add a new story','ar':'إضافة قصة جديدة','tr':'Yeni hikâye ekle'},
  'در حال بارگذاری استوری…': {'en':'Uploading story…','ar':'جارٍ رفع القصة…','tr':'Hikâye yükleniyor…'},
  'شناسه رسانه دریافت نشد.': {'en':'Media ID was not returned.','ar':'لم يتم استلام معرّف الوسائط.','tr':'Medya kimliği alınamadı.'},
  'استوری تا ۲۴ ساعت نمایش داده می‌شود.': {'en':'Your story will be visible for 24 hours.','ar':'ستظهر قصتك لمدة 24 ساعة.','tr':'Hikâyen 24 saat boyunca görünür.'},
  'من': {'en':'Me','ar':'أنا','tr':'Ben'},
  'استوری من': {'en':'My story','ar':'قصتي','tr':'Hikâyem'},
  'کاربر': {'en':'User','ar':'مستخدم','tr':'Kullanıcı'},
  'استوری': {'en':'Story','ar':'قصة','tr':'Hikâye'},
  'متن پست کپی شد.': {'en':'Post text copied.','ar':'تم نسخ نص المنشور.','tr':'Gönderi metni kopyalandı.'},
  'پست جدید': {'en':'New post','ar':'منشور جديد','tr':'Yeni gönderi'},
  'چه خبر؟  #هشتگ  @منشن': {'en':"What's happening?  #hashtag  @mention",'ar':'ما الجديد؟  #وسم  @إشارة','tr':'Neler oluyor?  #etiket  @bahset'},
  'انصراف': {'en':'Cancel','ar':'إلغاء','tr':'İptal'},
  'ذخیره': {'en':'Save','ar':'حفظ','tr':'Kaydet'},
  'لغو': {'en':'Cancel','ar':'إلغاء','tr':'İptal'},
  'حذف': {'en':'Delete','ar':'حذف','tr':'Sil'},
  'کامنت ثبت شد.': {'en':'Comment posted.','ar':'تم نشر التعليق.','tr':'Yorum gönderildi.'},
  'پست ویرایش شد.': {'en':'Post updated.','ar':'تم تعديل المنشور.','tr':'Gönderi güncellendi.'},
  'پست حذف شد.': {'en':'Post deleted.','ar':'تم حذف المنشور.','tr':'Gönderi silindi.'},
  'حساب تأییدشده': {'en':'Verified account','ar':'حساب موثّق','tr':'Onaylı hesap'},
  'کامنت‌های این پست': {'en':'Comments on this post','ar':'التعليقات على هذا المنشور','tr':'Bu gönderinin yorumları'},
  'هنوز کامنتی ثبت نشده؛ اولین نفر باش.': {'en':'No comments yet. Be the first.','ar':'لا توجد تعليقات بعد. كن أول من يعلّق.','tr':'Henüz yorum yok. İlk yorumu sen yap.'},
  'حذف پست': {'en':'Delete post','ar':'حذف المنشور','tr':'Gönderiyi sil'},
  'حذف از ذخیره‌ها': {'en':'Remove from saved','ar':'إزالة من المحفوظات','tr':'Kaydedilenlerden kaldır'},
  'ذخیره پست': {'en':'Save post','ar':'حفظ المنشور','tr':'Gönderiyi kaydet'},
  'جست‌وجوی کاربر': {'en':'Search users','ar':'البحث عن المستخدمين','tr':'Kullanıcı ara'},
  'ابزارها و تنظیمات': {'en':'Tools & settings','ar':'الأدوات والإعدادات','tr':'Araçlar ve ayarlar'},
  'آمار حساب': {'en':'Account insights','ar':'إحصاءات الحساب','tr':'Hesap istatistikleri'},
  'حالت روشن': {'en':'Light mode','ar':'الوضع الفاتح','tr':'Açık tema'},
  'حالت تیره': {'en':'Dark mode','ar':'الوضع الداكن','tr':'Koyu tema'},
  'بارگذاری پروفایل انجام نشد.': {'en':'Could not load profile.','ar':'تعذر تحميل الملف الشخصي.','tr':'Profil yüklenemedi.'},
  'دنبال‌کنندگان': {'en':'Followers','ar':'المتابعون','tr':'Takipçiler'},
  'دنبال‌شوندگان': {'en':'Following','ar':'المتابَعون','tr':'Takip edilenler'},
  'هنوز کسی اینجا نیست.': {'en':'Nothing here yet.','ar':'لا يوجد شيء هنا بعد.','tr':'Burada henüz kimse yok.'},
  'تلاش دوباره': {'en':'Try again','ar':'حاول مجدداً','tr':'Tekrar dene'},
  'دنبال‌کننده': {'en':'Follower','ar':'متابع','tr':'Takipçi'},
  'دنبال‌شونده': {'en':'Following','ar':'يتابعه','tr':'Takip ediliyor'},
  'کمی صبر کن…': {'en':'Please wait…','ar':'يرجى الانتظار…','tr':'Lütfen bekle…'},
  'دنبال می‌کنی': {'en':'Following','ar':'تتابعه','tr':'Takip ediliyor'},
  'دنبال‌کردن': {'en':'Follow','ar':'متابعة','tr':'Takip et'},
  'هنوز پستی منتشر نشده.': {'en':'No posts published yet.','ar':'لم يتم نشر أي منشورات بعد.','tr':'Henüz gönderi paylaşılmadı.'},
  'یک خطای غیرمنتظره رخ داد. دوباره تلاش کن.': {'en':'Something went wrong. Please try again.','ar':'حدث خطأ غير متوقع. حاول مجدداً.','tr':'Beklenmeyen bir hata oluştu. Tekrar dene.'},
  'پاسخی دریافت نشد.': {'en':'No response received.','ar':'لم يتم استلام أي رد.','tr':'Yanıt alınamadı.'},
  'نشان آبی': {'en':'Blue badge','ar':'شارة زرقاء','tr':'Mavi rozet'},
  'دارد': {'en':'Yes','ar':'نعم','tr':'Var'},
  'ندارد': {'en':'No','ar':'لا','tr':'Yok'},
  'پست‌های مرتبط / اخیر': {'en':'Related / recent posts','ar':'المنشورات ذات الصلة / الحديثة','tr':'İlgili / son gönderiler'},
  'گفت‌وگوی تازه': {'en':'New conversation','ar':'محادثة جديدة','tr':'Yeni sohbet'},
  'پرسش کن؛ داده‌ها را شفاف ببین.': {'en':'Ask questions and inspect the data.','ar':'اطرح الأسئلة واستعرض البيانات بوضوح.','tr':'Sor ve verileri şeffafça incele.'},
  'در حال بررسی داده‌ها…': {'en':'Analyzing data…','ar':'جارٍ تحليل البيانات…','tr':'Veriler inceleniyor…'},
  'از BinerAI چیزی بپرس…': {'en':'Ask BinerAI…','ar':'اسأل BinerAI…','tr':'BinerAI’ye sor…'},
  'هنوز داده‌ای ثبت نشده': {'en':'No data recorded yet','ar':'لم يتم تسجيل بيانات بعد','tr':'Henüz veri kaydedilmedi'},
  'کمتر از یک دقیقه': {'en':'Less than a minute','ar':'أقل من دقيقة','tr':'Bir dakikadan az'},
  'به‌روزرسانی آمار': {'en':'Refresh insights','ar':'تحديث الإحصاءات','tr':'İstatistikleri yenile'},
  'آمار بارگذاری نشد': {'en':'Could not load insights','ar':'تعذر تحميل الإحصاءات','tr':'İstatistikler yüklenemedi'},
  'اتصال به سرور یا دسترسی API را بررسی کن و دوباره تلاش کن.': {'en':'Check the server connection and API access, then try again.','ar':'تحقق من اتصال الخادم وإمكانية الوصول إلى API ثم حاول مجدداً.','tr':'Sunucu bağlantısını ve API erişimini kontrol edip tekrar dene.'},
  'پست‌های منتشرشده': {'en':'Published posts','ar':'المنشورات المنشورة','tr':'Paylaşılan gönderiler'},
  'لایک دریافتی': {'en':'Likes received','ar':'الإعجابات المستلمة','tr':'Alınan beğeniler'},
  'بازنشر دریافتی': {'en':'Reposts received','ar':'إعادات النشر المستلمة','tr':'Alınan yeniden paylaşımlar'},
  'کامنت دریافتی': {'en':'Comments received','ar':'التعليقات المستلمة','tr':'Alınan yorumlar'},
  'بازدید ثبت‌شده': {'en':'Recorded views','ar':'المشاهدات المسجلة','tr':'Kaydedilen görüntülemeler'},
  'نمای کلی حساب': {'en':'Account overview','ar':'نظرة عامة على الحساب','tr':'Hesaba genel bakış'},
  'عملکرد حساب': {'en':'Account performance','ar':'أداء الحساب','tr':'Hesap performansı'},
  'مجموع داده‌های ثبت‌شده تا این لحظه': {'en':'All data recorded so far','ar':'إجمالي البيانات المسجلة حتى الآن','tr':'Şimdiye kadar kaydedilen tüm veriler'},
  'زمان مطالعه': {'en':'Reading time','ar':'وقت القراءة','tr':'Okuma süresi'},
  'پست‌های پربازده': {'en':'Top-performing posts','ar':'المنشورات الأعلى أداءً','tr':'En iyi performans gösteren gönderiler'},
  'هنوز دادهٔ کافی نداریم': {'en':'Not enough data yet','ar':'لا توجد بيانات كافية بعد','tr':'Henüz yeterli veri yok'},
  'ساخت اتاق گفتگو': {'en':'Create a chat room','ar':'إنشاء غرفة محادثة','tr':'Sohbet odası oluştur'},
  'نام گروه': {'en':'Group name','ar':'اسم المجموعة','tr':'Grup adı'},
  'ساخت گروه': {'en':'Create group','ar':'إنشاء مجموعة','tr':'Grup oluştur'},
  'ورود به گروه': {'en':'Join a group','ar':'الانضمام إلى مجموعة','tr':'Gruba katıl'},
  'ورود': {'en':'Join','ar':'دخول','tr':'Katıl'},
  'اتاق‌های گفتگو': {'en':'Chat rooms','ar':'غرف المحادثة','tr':'Sohbet odaları'},
  'ورود با لینک': {'en':'Join with link','ar':'الانضمام عبر رابط','tr':'Bağlantıyla katıl'},
  'گروه‌ها بارگذاری نشدند': {'en':'Could not load groups','ar':'تعذر تحميل المجموعات','tr':'Gruplar yüklenemedi'},
  'اتصال API را بررسی کن و دوباره تلاش کن.': {'en':'Check the API connection and try again.','ar':'تحقق من اتصال API وحاول مجدداً.','tr':'API bağlantısını kontrol edip tekrar dene.'},
  'هنوز عضو گروهی نیستی': {'en':'You are not in any groups yet','ar':'لست عضواً في أي مجموعة بعد','tr':'Henüz hiçbir grupta değilsin'},
  'یک اتاق گفتگو بساز یا با لینک داخلی bm: به گروهی بپیوند.': {'en':'Create a chat room or join a group with a bm: invite link.','ar':'أنشئ غرفة محادثة أو انضم إلى مجموعة عبر رابط bm:.','tr':'Bir sohbet odası oluştur veya bm: davet bağlantısıyla katıl.'},
  'گروه‌های تو': {'en':'Your groups','ar':'مجموعاتك','tr':'Grupların'},
  'گفتگوهای گروهی خصوصی و قابل مدیریت': {'en':'Private, manageable group conversations','ar':'محادثات جماعية خاصة وقابلة للإدارة','tr':'Özel ve yönetilebilir grup sohbetleri'},
  'کپی لینک گروه': {'en':'Copy group link','ar':'نسخ رابط المجموعة','tr':'Grup bağlantısını kopyala'},
  'لینک گروه کپی شد.': {'en':'Group link copied.','ar':'تم نسخ رابط المجموعة.','tr':'Grup bağlantısı kopyalandı.'},
  'بارگذاری پیام‌های گروه انجام نشد.': {'en':'Could not load group messages.','ar':'تعذر تحميل رسائل المجموعة.','tr':'Grup mesajları yüklenemedi.'},
  'ارسال پیام انجام نشد. دوباره تلاش کن.': {'en':'Message could not be sent. Try again.','ar':'تعذر إرسال الرسالة. حاول مجدداً.','tr':'Mesaj gönderilemedi. Tekrar dene.'},
  'به‌روزرسانی': {'en':'Refresh','ar':'تحديث','tr':'Yenile'},
  'پیام‌ها برای اعضای گروه قابل مشاهده‌اند.': {'en':'Messages are visible to group members.','ar':'الرسائل مرئية لأعضاء المجموعة.','tr':'Mesajlar grup üyelerine görünür.'},
  'ارسال عکس یا ویدیو': {'en':'Send photo or video','ar':'إرسال صورة أو فيديو','tr':'Fotoğraf veya video gönder'},
  'پیام گروه…': {'en':'Message the group…','ar':'أرسل رسالة إلى المجموعة…','tr':'Gruba mesaj yaz…'},
  'رسانه': {'en':'Media','ar':'وسائط','tr':'Medya'},
  'سرعت پخش': {'en':'Playback speed','ar':'سرعة التشغيل','tr':'Oynatma hızı'},
  'پخش ویدیو ممکن نشد.': {'en':'Video playback failed.','ar':'تعذر تشغيل الفيديو.','tr':'Video oynatılamadı.'},
  'گاوصندوق پیش‌نویس‌ها': {'en':'Draft vault','ar':'خزنة المسودات','tr':'Taslak kasası'},
  'پیش‌نویس تازه': {'en':'New draft','ar':'مسودة جديدة','tr':'Yeni taslak'},
  'هنوز پیش‌نویسی ذخیره نکردی.': {'en':'You have no saved drafts yet.','ar':'لم تحفظ أي مسودات بعد.','tr':'Henüz taslak kaydetmedin.'},
  'آزمایشگاه هشتگ': {'en':'Hashtag lab','ar':'مختبر الوسوم','tr':'Etiket laboratuvarı'},
  'موضوع یا چند کلمه وارد کن؛ هشتگ‌های پیشنهادی به‌صورت محلی ساخته می‌شوند.': {'en':'Enter a topic or a few words to generate hashtag suggestions on-device.','ar':'أدخل موضوعاً أو بضع كلمات لإنشاء وسوم مقترحة على جهازك.','tr':'Cihazında etiket önerileri oluşturmak için bir konu veya birkaç kelime gir.'},
  'مثلاً برنامه‌نویسی، تکنولوژی، هنر': {'en':'e.g. programming, technology, art','ar':'مثلاً البرمجة والتقنية والفن','tr':'örn. programlama, teknoloji, sanat'},
  'ساخت هشتگ': {'en':'Generate hashtags','ar':'إنشاء وسوم','tr':'Etiket oluştur'},
  'کپی هشتگ‌ها': {'en':'Copy hashtags','ar':'نسخ الوسوم','tr':'Etiketleri kopyala'},
  'کارگاه ویرایش متن': {'en':'Text editor workshop','ar':'ورشة تحرير النصوص','tr':'Metin düzenleme atölyesi'},
  'متن را مرتب کن و نسخهٔ تمیزشده را کپی کن.': {'en':'Format your text and copy the cleaned version.','ar':'نسّق النص وانسخ النسخة المنقحة.','tr':'Metnini düzenle ve temizlenmiş sürümü kopyala.'},
  'متن خودت را وارد کن…': {'en':'Enter your text…','ar':'أدخل النص…','tr':'Metnini gir…'},
  'پاک‌سازی فاصله‌ها': {'en':'Clean spacing','ar':'تنظيف المسافات','tr':'Boşlukları temizle'},
  'فهرست‌سازی': {'en':'Make a list','ar':'إنشاء قائمة','tr':'Liste oluştur'},
  'نقل‌قول': {'en':'Quote','ar':'اقتباس','tr':'Alıntı'},
  'کپی خروجی': {'en':'Copy output','ar':'نسخ الناتج','tr':'Çıktıyı kopyala'},
  'کتابخانهٔ پاسخ‌های آماده': {'en':'Quick replies library','ar':'مكتبة الردود الجاهزة','tr':'Hazır yanıt kitaplığı'},
  'افزودن پاسخ آماده': {'en':'Add quick reply','ar':'إضافة رد جاهز','tr':'Hazır yanıt ekle'},
  'پاسخ آمادهٔ جدید': {'en':'New quick reply','ar':'رد جاهز جديد','tr':'Yeni hazır yanıt'},
  'فیلتر واژه‌های دلخواه': {'en':'Muted words','ar':'الكلمات المكتومة','tr':'Sessize alınan kelimeler'},
  'واژه‌هایی که نمی‌خواهی در فید ببینی ذخیره کن. این فهرست آمادهٔ اتصال به فیلتر فید است.': {'en':'Save words you do not want to see in your feed.','ar':'احفظ الكلمات التي لا تريد رؤيتها في موجزك.','tr':'Akışında görmek istemediğin kelimeleri kaydet.'},
  'یک واژه یا عبارت': {'en':'A word or phrase','ar':'كلمة أو عبارة','tr':'Bir kelime veya ifade'},
  'افزودن واژه': {'en':'Add word','ar':'إضافة كلمة','tr':'Kelime ekle'},
  'حالت مطالعهٔ متمرکز': {'en':'Focus reading mode','ar':'وضع القراءة المركّز','tr':'Odaklı okuma modu'},
  'متن یک پست را اینجا قرار بده تا بدون شلوغی و با خوانایی بیشتر نمایش داده شود.': {'en':'Paste a post here to read it in a clean, distraction-free layout.','ar':'ألصق منشوراً هنا لقراءته بتنسيق واضح وخالٍ من التشتيت.','tr':'Dikkat dağıtmayan, okunaklı bir düzende okumak için gönderiyi buraya yapıştır.'},
  'متن پست…': {'en':'Post text…','ar':'نص المنشور…','tr':'Gönderi metni…'},
  'شروع مطالعه': {'en':'Start reading','ar':'بدء القراءة','tr':'Okumaya başla'},
  'استودیوی بیوگرافی': {'en':'Bio studio','ar':'استوديو النبذة','tr':'Biyografi stüdyosu'},
  'بیوی کوتاه پروفایلت را بنویس، پیش‌نمایش بگیر و کپی کن.': {'en':'Write, preview and copy your profile bio.','ar':'اكتب نبذة ملفك الشخصي واعرضها ثم انسخها.','tr':'Profil biyografini yaz, önizle ve kopyala.'},
  'علاقه‌مندی‌ها، تخصص‌ها و لینک‌ها…': {'en':'Interests, skills and links…','ar':'الاهتمامات والمهارات والروابط…','tr':'İlgi alanları, uzmanlıklar ve bağlantılar…'},
  'پیش‌نمایش پروفایل': {'en':'Profile preview','ar':'معاينة الملف الشخصي','tr':'Profil önizlemesi'},
  'بیوی تو اینجا نمایش داده می‌شود.': {'en':'Your bio will appear here.','ar':'ستظهر نبذتك هنا.','tr':'Biyografin burada görünecek.'},
  'کپی بیو': {'en':'Copy bio','ar':'نسخ النبذة','tr':'Biyografiyi kopyala'},
  'مولد ایدهٔ پست': {'en':'Post idea generator','ar':'مولّد أفكار المنشورات','tr':'Gönderi fikri oluşturucu'},
  'برای شروع نوشتن، یک جرقهٔ تازه بگیر.': {'en':'Get a fresh spark to start writing.','ar':'احصل على فكرة جديدة لبدء الكتابة.','tr':'Yazmaya başlamak için yeni bir fikir edin.'},
  'ایدهٔ بعدی': {'en':'Next idea','ar':'الفكرة التالية','tr':'Sonraki fikir'},
  'کپی ایده': {'en':'Copy idea','ar':'نسخ الفكرة','tr':'Fikri kopyala'},
  'برای شروع، یک ایده انتخاب کن.': {'en':'Choose an idea to get started.','ar':'اختر فكرة للبدء.','tr':'Başlamak için bir fikir seç.'},
  'برنامه‌ریز رشته‌پست': {'en':'Thread planner','ar':'مخطط سلسلة المنشورات','tr':'Dizi gönderi planlayıcı'},
  'یک متن بلند را به بخش‌های حداکثر ۲۸۰ نویسه‌ای تقسیم کن.': {'en':'Split long text into sections of up to 280 characters.','ar':'قسّم النص الطويل إلى أجزاء لا تتجاوز 280 حرفاً.','tr':'Uzun metni en fazla 280 karakterlik bölümlere ayır.'},
  'متن کامل رشته‌پست…': {'en':'Full thread text…','ar':'نص السلسلة بالكامل…','tr':'Dizi gönderinin tam metni…'},
  'تقسیم متن': {'en':'Split text','ar':'تقسيم النص','tr':'Metni böl'},
  'کپی کل رشته‌پست': {'en':'Copy entire thread','ar':'نسخ السلسلة كاملة','tr':'Tüm diziyi kopyala'},
  'بستن': {'en':'Close','ar':'إغلاق','tr':'Kapat'},
  'تحلیل‌گر متن': {'en':'Text analyzer','ar':'محلل النصوص','tr':'Metin analiz aracı'},
  'آمار زندهٔ نوشته؛ همه‌چیز روی خود دستگاه محاسبه می‌شود.': {'en':'Live writing stats, calculated on your device.','ar':'إحصاءات الكتابة مباشرة، وتُحسب على جهازك.','tr':'Canlı yazı istatistikleri cihazında hesaplanır.'},
  'متنت را وارد کن…': {'en':'Enter your text…','ar':'أدخل النص…','tr':'Metnini gir…'},
  'نویسه': {'en':'Characters','ar':'الأحرف','tr':'Karakter'},
  'واژه': {'en':'Words','ar':'الكلمات','tr':'Kelime'},
  'هشتگ': {'en':'Hashtag','ar':'وسم','tr':'Etiket'},
  'منشن': {'en':'Mention','ar':'إشارة','tr':'Bahsetme'},
  'مطالعه': {'en':'Reading','ar':'قراءة','tr':'Okuma'},
  'ایده‌ات را به محتوا تبدیل کن.': {'en':'Turn your ideas into content.','ar':'حوّل أفكارك إلى محتوى.','tr':'Fikirlerini içeriğe dönüştür.'},
  '۱۰ ابزار کاربردی برای نوشتن، مدیریت متن و ساخت محتوای بهتر.': {'en':'10 practical tools for writing, editing and creating better content.','ar':'10 أدوات عملية للكتابة والتحرير وإنشاء محتوى أفضل.','tr':'Yazma, düzenleme ve daha iyi içerik üretmek için 10 pratik araç.'},
  'پیش‌نویس': {'en':'Drafts','ar':'المسودات','tr':'Taslaklar'},
  'عبارت آماده': {'en':'Quick replies','ar':'ردود جاهزة','tr':'Hazır yanıtlar'},
  'فیلتر': {'en':'Filter','ar':'تصفية','tr':'Filtre'},
  'کپی شد': {'en':'Copied','ar':'تم النسخ','tr':'Kopyalandı'},
  'متن': {'en':'Text','ar':'نص','tr':'Metin'},
  'اینجا بنویس…': {'en':'Write here…','ar':'اكتب هنا…','tr':'Buraya yaz…'},
  'ذخیره تغییرات': {'en':'Save changes','ar':'حفظ التغييرات','tr':'Değişiklikleri kaydet'},
  'گزینه‌های نظرسنجی': {'en':'Poll options','ar':'خيارات الاستطلاع','tr':'Anket seçenekleri'},
  'افزودن هشتگ': {'en':'Add hashtag','ar':'إضافة وسم','tr':'Etiket ekle'},
  'منشن کردن کاربر': {'en':'Mention a user','ar':'الإشارة إلى مستخدم','tr':'Kullanıcıdan bahset'},
  'افزودن نظرسنجی': {'en':'Add poll','ar':'إضافة استطلاع','tr':'Anket ekle'},
  'افزودن عکس یا ویدیو': {'en':'Add photo or video','ar':'إضافة صورة أو فيديو','tr':'Fotoğraf veya video ekle'},
  'انتشار': {'en':'Publish','ar':'نشر','tr':'Paylaş'},
  'نظرسنجی باید ۲ تا ۴ گزینه داشته باشد.': {'en':'A poll needs 2 to 4 options.','ar':'يجب أن يحتوي الاستطلاع على خيارين إلى أربعة.','tr':'Anket 2–4 seçenek içermeli.'},
  'ویرایش پست': {'en':'Edit post','ar':'تعديل المنشور','tr':'Gönderiyi düzenle'},
  'حذف پست؟': {'en':'Delete post?','ar':'حذف المنشور؟','tr':'Gönderi silinsin mi?'},
  'این کار پست را از فید حذف می‌کند.': {'en':'This will remove the post from your feed.','ar':'سيؤدي هذا إلى إزالة المنشور من موجزك.','tr':'Bu işlem gönderiyi akışından kaldırır.'},
  'برای رأی دادن انتخاب کن': {'en':'Select an option to vote','ar':'اختر خياراً للتصويت','tr':'Oy vermek için bir seçenek seç'},
  'رأی ثبت شد': {'en':'Vote recorded','ar':'تم تسجيل التصويت','tr':'Oy kaydedildi'},
  'بازگشت': {'en':'Back','ar':'رجوع','tr':'Geri'},
  'Creator Studio · ۱۰ ابزار': {'en':'Creator Studio · 10 tools','ar':'استوديو المنشئ · 10 أدوات','tr':'Creator Studio · 10 araç'},
  'ممنون از اینکه دیدگاهت را به اشتراک گذاشتی.': {'en':'Thanks for sharing your thoughts.','ar':'شكراً لمشاركة رأيك.','tr':'Düşüncelerini paylaştığın için teşekkürler.'},
  'این موضوع ارزش بررسی بیشتری دارد.': {'en':'This topic deserves a closer look.','ar':'هذا الموضوع يستحق مزيداً من البحث.','tr':'Bu konu daha yakından incelenmeyi hak ediyor.'},
  'یک نکتهٔ مهم که نباید فراموش کنیم:': {'en':'One important point to remember:','ar':'نقطة مهمة يجب ألا ننساها:','tr':'Unutmamamız gereken önemli bir nokta:'},
  'نوشتن را ذخیره کن و بعداً ادامه بده': {'en':'Save your writing and continue later','ar':'احفظ كتابتك وتابع لاحقاً','tr':'Yazını kaydet ve daha sonra devam et'},
  'ساخت هشتگ از موضوع و کلیدواژه': {'en':'Generate hashtags from a topic and keywords','ar':'إنشاء وسوم من موضوع وكلمات مفتاحية','tr':'Konu ve anahtar kelimelerden etiket oluştur'},
  'پاک‌سازی فاصله، نقل‌قول و فهرست‌سازی': {'en':'Clean spacing, quote and format lists','ar':'تنظيف المسافات والاقتباس وتنسيق القوائم','tr':'Boşlukları temizle, alıntı ve liste biçimlendir'},
  'عبارت‌های پرکاربردت را سریع کپی کن': {'en':'Copy your frequently used phrases quickly','ar':'انسخ عباراتك المتكررة بسرعة','tr':'Sık kullandığın ifadeleri hızla kopyala'},
  'فهرست واژه‌هایی که نمی‌خواهی ببینی': {'en':'A list of words you do not want to see','ar':'قائمة بالكلمات التي لا تريد رؤيتها','tr':'Görmek istemediğin kelimelerin listesi'},
  'خواندن متن در محیط خلوت و خوانا': {'en':'Read in a clean, readable space','ar':'اقرأ في مساحة هادئة وواضحة','tr':'Sade ve okunaklı bir alanda oku'},
  'ساخت و پیش‌نمایش بیوی پروفایل': {'en':'Create and preview your profile bio','ar':'إنشاء ومعاينة نبذة ملفك الشخصي','tr':'Profil biyografisi oluştur ve önizle'},
  'پیشنهاد موضوع برای انتشار بعدی': {'en':'Suggest a topic for your next post','ar':'اقتراح موضوع لمنشورك التالي','tr':'Sonraki paylaşımın için konu öner'},
  'آمار نویسه، واژه، هشتگ و زمان مطالعه': {'en':'Character, word, hashtag and reading-time stats','ar':'إحصاءات الأحرف والكلمات والوسوم ووقت القراءة','tr':'Karakter, kelime, etiket ve okuma süresi istatistikleri'},
  'تقسیم متن بلند به پست‌های کوتاه': {'en':'Split long text into short posts','ar':'تقسيم النص الطويل إلى منشورات قصيرة','tr':'Uzun metni kısa gönderilere böl'},
  'یک ابزار دیجیتال که زندگی روزمره را ساده‌تر می‌کند معرفی کن.': {'en':'Introduce a digital tool that makes everyday life easier.','ar':'عرّف بأداة رقمية تجعل الحياة اليومية أسهل.','tr':'Günlük hayatı kolaylaştıran dijital bir araç tanıt.'},
  'از یک اشتباه جالب که چیز مهمی به تو یاد داد بنویس.': {'en':'Write about an interesting mistake that taught you something important.','ar':'اكتب عن خطأ مثير علّمك شيئاً مهماً.','tr':'Sana önemli bir şey öğreten ilginç bir hatayı anlat.'},
  'یک باور رایج در دنیای فناوری را به چالش بکش.': {'en':'Challenge a common belief in the tech world.','ar':'تحدَّ اعتقاداً شائعاً في عالم التقنية.','tr':'Teknoloji dünyasındaki yaygın bir inanışı sorgula.'},
  'سه منبع رایگان برای یادگیری یک مهارت معرفی کن.': {'en':'Share three free resources for learning a skill.','ar':'اقترح ثلاثة مصادر مجانية لتعلم مهارة.','tr':'Bir beceri öğrenmek için üç ücretsiz kaynak öner.'},
  'اگر می‌توانستی یک قابلیت به شبکه‌های اجتماعی اضافه کنی، چه بود؟': {'en':'If you could add one feature to social media, what would it be?','ar':'إذا استطعت إضافة ميزة إلى الشبكات الاجتماعية، فما هي؟','tr':'Sosyal medyaya bir özellik ekleyebilseydin bu ne olurdu?'},
  'یک پروژهٔ کوچک را از ایده تا نتیجه روایت کن.': {'en':'Tell the story of a small project from idea to result.','ar':'احكِ قصة مشروع صغير من الفكرة إلى النتيجة.','tr':'Küçük bir projeyi fikirden sonuca anlat.'},
  'یک کتاب یا فیلم که نگاهت را تغییر داد معرفی کن.': {'en':'Recommend a book or film that changed your perspective.','ar':'رشّح كتاباً أو فيلماً غيّر نظرتك.','tr':'Bakış açını değiştiren bir kitap veya film öner.'},
  'یک سؤال بپرس که باعث شروع یک گفت‌وگوی واقعی شود.': {'en':'Ask a question that starts a meaningful conversation.','ar':'اطرح سؤالاً يفتح حواراً حقيقياً.','tr':'Gerçek bir sohbet başlatacak bir soru sor.'},
  'درباره @hirad990 چه اطلاعاتی در BinerMention ثبت شده؟': {'en':'What information about @hirad990 is available on BinerMention?','ar':'ما المعلومات المتاحة عن @hirad990 في BinerMention؟','tr':'BinerMention üzerinde @hirad990 hakkında hangi bilgiler var?'},
  'آخرین پست‌های @hirad990 را نشان بده': {'en':'Show the latest posts by @hirad990','ar':'اعرض أحدث منشورات @hirad990','tr':'@hirad990 kullanıcısının son gönderilerini göster'},
  'درباره این موضوع چه پست‌هایی منتشر شده؟': {'en':'What posts have been published about this topic?','ar':'ما المنشورات التي نُشرت حول هذا الموضوع؟','tr':'Bu konu hakkında hangi gönderiler paylaşıldı?'},
  'BinerAI اطلاعات موجود در BinerMention، آمار حساب‌ها و پست‌های عمومی را بررسی می‌کند. این نسخه هنوز جست‌وجوی وب بیرونی ندارد.': {'en':'BinerAI analyzes available BinerMention data, account insights and public posts. This version does not search the external web.','ar':'يحلل BinerAI البيانات المتاحة في BinerMention وإحصاءات الحسابات والمنشورات العامة. لا يدعم هذا الإصدار البحث على الويب الخارجي بعد.','tr':'BinerAI, BinerMention verilerini, hesap istatistiklerini ve herkese açık gönderileri inceler. Bu sürümde harici web araması yoktur.'},
  'آمار از رویدادهای ثبت‌شده در BinerMention محاسبه می‌شود؛ هر شاخص باید قابل ردیابی و توضیح باشد.': {'en':'Insights are calculated from recorded BinerMention events; every metric is traceable and explainable.','ar':'تُحسب الإحصاءات من أحداث BinerMention المسجلة، ويمكن تتبع كل مؤشر وتفسيره.','tr':'İstatistikler kaydedilen BinerMention etkinliklerinden hesaplanır; her ölçüm izlenebilir ve açıklanabilir.'},
  'مجموع زمان تعامل ثبت‌شده با پست‌های عمومی تو': {'en':'Total recorded time spent engaging with your public posts','ar':'إجمالي الوقت المسجل للتفاعل مع منشوراتك العامة','tr':'Herkese açık gönderilerinle etkileşim için kaydedilen toplam süre'},
  'این شاخص از زمان فعال‌شدن ثبت رویدادها معتبر است.': {'en':'This metric is valid from the time event tracking was enabled.','ar':'هذا المؤشر صالح منذ تفعيل تسجيل الأحداث.','tr':'Bu ölçüm, etkinlik kaydı etkinleştirildiği tarihten itibaren geçerlidir.'},
  'بر اساس لایک، بازنشر و کامنت': {'en':'Based on likes, reposts and comments','ar':'بناءً على الإعجابات وإعادة النشر والتعليقات','tr':'Beğeni, yeniden paylaşım ve yorumlara göre'},
  'با انتشار پست و دریافت تعامل، این بخش به‌تدریج کامل می‌شود.': {'en':'This section fills in as you publish posts and receive engagement.','ar':'سيكتمل هذا القسم تدريجياً عند نشر المنشورات وتلقي التفاعل.','tr':'Gönderi paylaşıp etkileşim aldıkça bu bölüm tamamlanır.'},
  'آمار فقط از داده‌های ذخیره‌شده در سامانه محاسبه می‌شود.': {'en':'Insights are calculated only from data stored in the system.','ar':'تُحسب الإحصاءات من البيانات المخزنة في النظام فقط.','tr':'İstatistikler yalnızca sistemde saklanan verilerden hesaplanır.'},
  'پست $display': {'en':'$display posts','ar':'$display منشورات','tr':'$display gönderi'},
  'گروه': {'en':'Group','ar':'مجموعة','tr':'Grup'},
  'پست': {'en':'Post','ar':'منشور','tr':'Gönderi'},
  'پست‌ها': {'en':'Posts','ar':'المنشورات','tr':'Gönderiler'},
  'پستی با این هشتگ پیدا نشد.': {'en':'No posts found for this hashtag.','ar':'لم يتم العثور على منشورات بهذا الوسم.','tr':'Bu etiket için gönderi bulunamadı.'},
  'هنوز پستی وجود ندارد.': {'en':'There are no posts yet.','ar':'لا توجد منشورات بعد.','tr':'Henüz gönderi yok.'},
  'اعلان‌ها بارگذاری نشدند': {'en':'Notifications could not be loaded','ar':'تعذر تحميل الإشعارات','tr':'Bildirimler yüklenemedi'},
  'اتصال به سرور را بررسی کن و دوباره وارد این بخش شو.': {'en':'Check your server connection and reopen this section.','ar':'تحقق من اتصال الخادم ثم افتح هذا القسم مجدداً.','tr':'Sunucu bağlantını kontrol edip bu bölümü yeniden aç.'},
  'اعلان تازه‌ای نداری': {'en':'You have no new notifications','ar':'ليس لديك إشعارات جديدة','tr':'Yeni bildirimin yok'},
  'وقتی کسی با پست یا حساب تو تعامل کند، اینجا می‌بینی.': {'en':'Interactions with your posts or account will appear here.','ar':'ستظهر هنا التفاعلات مع منشوراتك أو حسابك.','tr':'Gönderilerin veya hesabınla etkileşimler burada görünür.'},
  'در یک پست منشن‌ات کرد': {'en':'mentioned you in a post','ar':'أشار إليك في منشور','tr':'bir gönderide senden bahsetti'},
  'دنبال‌ات کرد': {'en':'followed you','ar':'بدأ بمتابعتك','tr':'seni takip etti'},
  'پستت را پسندید': {'en':'liked your post','ar':'أُعجب بمنشورك','tr':'gönderini beğendi'},
  'پستت را بازنشر کرد': {'en':'reposted your post','ar':'أعاد نشر منشورك','tr':'gönderini yeniden paylaştı'},
  'به پستت پاسخ داد': {'en':'replied to your post','ar':'رد على منشورك','tr':'gönderine yanıt verdi'},
  'پیام فرستاد': {'en':'sent you a message','ar':'أرسل إليك رسالة','tr':'sana mesaj gönderdi'},
  'استوری‌ات را پسندید': {'en':'liked your story','ar':'أُعجب بقصتك','tr':'hikâyeni beğendi'},
  'اعلان‌ها': {'en':'Notifications','ar':'الإشعارات','tr':'Bildirimler'},
  'آخرین اتفاق‌های مربوط به حساب تو': {'en':'Recent activity on your account','ar':'أحدث الأنشطة المتعلقة بحسابك','tr':'Hesabındaki son etkinlikler'},
  'تعامل جدید': {'en':'New interaction','ar':'تفاعل جديد','tr':'Yeni etkileşim'},
  'ادامه': {'en':'Continue','ar':'متابعة','tr':'Devam et'},
  'پاسخ سرور معتبر نیست.': {'en':'The server response is invalid.','ar':'استجابة الخادم غير صالحة.','tr':'Sunucu yanıtı geçersiz.'},
  'پیام‌ها بارگذاری نشدند': {'en':'Messages could not be loaded','ar':'تعذر تحميل الرسائل','tr':'Mesajlar yüklenemedi'},
  'وضعیت اتصال و API را بررسی کن.': {'en':'Check the connection and API status.','ar':'تحقق من الاتصال وحالة API.','tr':'Bağlantıyı ve API durumunu kontrol et.'},
  'پیام‌ها': {'en':'Messages','ar':'الرسائل','tr':'Mesajlar'},
  'گفتگوهای خصوصی و اتاق‌های گروهی': {'en':'Private chats and group rooms','ar':'المحادثات الخاصة والغرف الجماعية','tr':'Özel sohbetler ve grup odaları'},
  'پیام جدید': {'en':'New message','ar':'رسالة جديدة','tr':'Yeni mesaj'},
  'هنوز گفتگویی نداری': {'en':'No conversations yet','ar':'لا توجد محادثات بعد','tr':'Henüz sohbetin yok'},
  'برای شروع یک پیام تازه بساز یا وارد اتاق گفتگو شو.': {'en':'Start a new message or join a chat room.','ar':'ابدأ رسالة جديدة أو انضم إلى غرفة محادثة.','tr':'Yeni bir mesaj başlat veya sohbet odasına katıl.'},
  'گفتگو': {'en':'Conversation','ar':'محادثة','tr':'Sohbet'},
  'گفتگوی تازه': {'en':'New conversation','ar':'محادثة جديدة','tr':'Yeni sohbet'},
  'نام کاربری یا نام نمایشی…': {'en':'Username or display name…','ar':'اسم المستخدم أو الاسم الظاهر…','tr':'Kullanıcı adı veya görünen ad…'},
  'برای شروع، حداقل ۲ حرف بنویس.': {'en':'Type at least 2 characters to start.','ar':'اكتب حرفين على الأقل للبدء.','tr':'Başlamak için en az 2 karakter yaz.'},
  'کاربری پیدا نشد.': {'en':'No users found.','ar':'لم يتم العثور على مستخدمين.','tr':'Kullanıcı bulunamadı.'},
  'ویرایش پروفایل': {'en':'Edit profile','ar':'تعديل الملف الشخصي','tr':'Profili düzenle'},
  'فونت گوشی': {'en':'System font','ar':'خط النظام','tr':'Sistem yazı tipi'},
  'وزیرمتن': {'en':'Vazirmatn','ar':'Vazirmatn','tr':'Vazirmatn'},
  'فونت اصلی': {'en':'Default font','ar':'الخط الافتراضي','tr':'Varsayılan yazı tipi'},
  'انتخاب عکس پروفایل': {'en':'Choose profile photo','ar':'اختيار صورة الملف الشخصي','tr':'Profil fotoğrafı seç'},
  'تغییر عکس انتخاب‌شده': {'en':'Change selected photo','ar':'تغيير الصورة المحددة','tr':'Seçili fotoğrafı değiştir'},
  'شناسهٔ عکس از سرور دریافت نشد.': {'en':'The server did not return the photo ID.','ar':'لم يُرجع الخادم معرّف الصورة.','tr':'Sunucu fotoğraf kimliğini döndürmedi.'},
  'پروفایل ذخیره شد.': {'en':'Profile saved.','ar':'تم حفظ الملف الشخصي.','tr':'Profil kaydedildi.'},
  'به گروه اضافه شدی.': {'en':'You joined the group.','ar':'لقد انضممت إلى المجموعة.','tr':'Gruba katıldın.'},
  'شناسه فایل از سرور دریافت نشد.': {'en':'The server did not return a file ID.','ar':'لم يُرجع الخادم معرّف الملف.','tr':'Sunucu dosya kimliğini döndürmedi.'},
  'دلیل گزارش را بنویس…': {'en':'Describe the reason for your report…','ar':'اكتب سبب الإبلاغ…','tr':'Rapor nedenini yaz…'},
  'گزارش ثبت شد. ممنون که اطلاع دادی.': {'en':'Report submitted. Thanks for letting us know.','ar':'تم إرسال البلاغ. شكراً لإبلاغنا.','tr':'Rapor gönderildi. Bildirdiğin için teşekkürler.'},
  'پس از مسدودسازی، ارسال پیام در این گفت‌وگو متوقف می‌شود.': {'en':'After blocking, messaging in this conversation will stop.','ar':'بعد الحظر، سيتوقف إرسال الرسائل في هذه المحادثة.','tr':'Engelledikten sonra bu sohbette mesajlaşma durur.'},
  'کاربر مسدود شد.': {'en':'User blocked.','ar':'تم حظر المستخدم.','tr':'Kullanıcı engellendi.'},
  'متنی برای پردازش وجود ندارد.': {'en':'There is no text to process.','ar':'لا يوجد نص لمعالجته.','tr':'İşlenecek metin yok.'},
  'پردازش متن انجام نشد: $e': {'en':'Text processing failed: $e','ar':'تعذرت معالجة النص: $e','tr':'Metin işlenemedi: $e'},
  'متن پیام کپی شد.': {'en':'Message text copied.','ar':'تم نسخ نص الرسالة.','tr':'Mesaj metni kopyalandı.'},
  'برای بازارسال، ابتدا یک گفت‌وگوی دیگر بساز.': {'en':'Create another conversation before forwarding.','ar':'أنشئ محادثة أخرى قبل إعادة التوجيه.','tr':'İletmeden önce başka bir sohbet oluştur.'},
  'انتخاب مقصد بازارسال': {'en':'Choose forwarding destination','ar':'اختر وجهة إعادة التوجيه','tr':'İletme hedefini seç'},
  'گفت‌وگو': {'en':'Chat','ar':'محادثة','tr':'Sohbet'},
  '↗ بازارسال‌شده\n$body': {'en':'↗ Forwarded\n$body','ar':'↗ تمت إعادة التوجيه\n$body','tr':'↗ İletildi\n$body'},
  'پیام بازارسال شد.': {'en':'Message forwarded.','ar':'تمت إعادة توجيه الرسالة.','tr':'Mesaj iletildi.'},
  'گزارش گفت‌وگو': {'en':'Report conversation','ar':'الإبلاغ عن المحادثة','tr':'Sohbeti bildir'},
  'مسدود کردن کاربر': {'en':'Block user','ar':'حظر المستخدم','tr':'Kullanıcıyı engelle'},
  'ویرایش پیش‌نویس': {'en':'Edit draft','ar':'تعديل المسودة','tr':'Taslağı düzenle'},
  'کتابخانهٔ پاسخ آماده': {'en':'Quick reply library','ar':'مكتبة الردود الجاهزة','tr':'Hazır yanıt kitaplığı'},
  'فیلتر واژه‌ها': {'en':'Word filter','ar':'تصفية الكلمات','tr':'Kelime filtresi'},
  'حالت مطالعه': {'en':'Reading mode','ar':'وضع القراءة','tr':'Okuma modu'},
  ' کامنت': {'en':' comments','ar':' تعليقات','tr':' yorum'},
};
String binerText(String fa, {String? en, String? ar, String? tr}) {
  final language = BinerPreferences.instance.locale.languageCode;
  final dynamicTranslation = _translateDynamicBinerText(fa, language);
  if (dynamicTranslation != null) return dynamicTranslation;
  final translations = _binerTranslations[fa];
  switch (language) {
    case 'en': return en ?? translations?['en'] ?? fa;
    case 'ar': return ar ?? translations?['ar'] ?? en ?? translations?['en'] ?? fa;
    case 'tr': return tr ?? translations?['tr'] ?? en ?? translations?['en'] ?? fa;
    default: return fa;
  }
}

String? _translateDynamicBinerText(String value, String language) {
  final minute = RegExp(r'^(\d+) دقیقه$').firstMatch(value);
  if (minute != null) {
    final n = minute.group(1)!;
    return switch (language) { 'en' => '$n min', 'ar' => '$n دقيقة', 'tr' => '$n dk', _ => null };
  }
  final hour = RegExp(r'^(\d+) ساعت$').firstMatch(value);
  if (hour != null) {
    final n = hour.group(1)!;
    return switch (language) { 'en' => '$n hr', 'ar' => '$n ساعة', 'tr' => '$n sa', _ => null };
  }
  final chars = RegExp(r'^(\d+) نویسه$').firstMatch(value);
  if (chars != null) {
    final n = chars.group(1)!;
    return switch (language) { 'en' => '$n characters', 'ar' => '$n حرفاً', 'tr' => '$n karakter', _ => null };
  }
  final recent = RegExp(r'^(\d+) پیام اخیر$').firstMatch(value);
  if (recent != null) {
    final n = recent.group(1)!;
    return switch (language) { 'en' => '$n recent messages', 'ar' => '$n رسالة حديثة', 'tr' => '$n son mesaj', _ => null };
  }
  final reading = RegExp(r'^(\d+) واژه · حدود (\d+) دقیقه مطالعه$').firstMatch(value);
  if (reading != null) {
    final words = reading.group(1)!;
    final minutes = reading.group(2)!;
    return switch (language) {
      'en' => '$words words · about $minutes min read',
      'ar' => '$words كلمة · نحو $minutes دقيقة قراءة',
      'tr' => '$words kelime · yaklaşık $minutes dk okuma',
      _ => null,
    };
  }
  final sections = RegExp(r'^(\d+) بخش آماده شد$').firstMatch(value);
  if (sections != null) {
    final n = sections.group(1)!;
    return switch (language) { 'en' => '$n sections ready', 'ar' => 'تم تجهيز $n أقسام', 'tr' => '$n bölüm hazır', _ => null };
  }
  final section = RegExp(r'^بخش (\d+) · (\d+)/280$').firstMatch(value);
  if (section != null) {
    final n = section.group(1)!;
    final chars = section.group(2)!;
    return switch (language) { 'en' => 'Part $n · $chars/280', 'ar' => 'الجزء $n · $chars/280', 'tr' => 'Bölüm $n · $chars/280', _ => null };
  }
  final hoursMinutes = RegExp(r'^(\d+) ساعت و (\d+) دقیقه
  if (members != null) {
    final n = members.group(1)!;
    final last = members.group(2)!;
    return switch (language) {
      'en' => '$n members · $last',
      'ar' => '$n أعضاء · $last',
      'tr' => '$n üye · $last',
      _ => null,
    };
  }
  return null;
}
).firstMatch(value);
  if (hoursMinutes != null) {
    final hours = hoursMinutes.group(1)!;
    final minutes = hoursMinutes.group(2)!;
    return switch (language) {
      'en' => '$hours hr $minutes min',
      'ar' => '$hours ساعة و $minutes دقيقة',
      'tr' => '$hours sa $minutes dk',
      _ => null,
    };
  }
  final reply = RegExp(r'^پاسخ به پست #(\d+)
  if (members != null) {
    final n = members.group(1)!;
    final last = members.group(2)!;
    return switch (language) {
      'en' => '$n members · $last',
      'ar' => '$n أعضاء · $last',
      'tr' => '$n üye · $last',
      _ => null,
    };
  }
  return null;
}
).firstMatch(value);
  if (reply != null) {
    final id = reply.group(1)!;
    return switch (language) { 'en' => 'Reply to post #$id', 'ar' => 'الرد على المنشور #$id', 'tr' => '#$id gönderisine yanıt', _ => null };
  }
  final members = RegExp(r'^(\d+) عضو  ·  (.*)
  if (members != null) {
    final n = members.group(1)!;
    final last = members.group(2)!;
    return switch (language) {
      'en' => '$n members · $last',
      'ar' => '$n أعضاء · $last',
      'tr' => '$n üye · $last',
      _ => null,
    };
  }
  return null;
}
).firstMatch(value);
  if (members != null) {
    final n = members.group(1)!;
    final last = members.group(2)!;
    return switch (language) {
      'en' => '$n members · $last',
      'ar' => '$n أعضاء · $last',
      'tr' => '$n üye · $last',
      _ => null,
    };
  }
  return null;
}
