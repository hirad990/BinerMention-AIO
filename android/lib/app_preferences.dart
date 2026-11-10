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
// UI copy is bundled locally: language switching never depends on a
// translation network or an API key.
const Map<String, List<String>> _uiTranslations = {
  'کاربر': ['User', 'مستخدم', 'Kullanıcı'],
  'دنبال‌کننده': ['Follower', 'متابع', 'Takipçi'],
  'دنبال‌کنندگان': ['Followers', 'المتابعون', 'Takipçiler'],
  'دنبال‌شونده': ['Following', 'المتابَعون', 'Takip edilen'],
  'دنبال‌شوندگان': ['Following', 'المتابَعون', 'Takip edilenler'],
  'پست': ['Post', 'منشور', 'Gönderi'],
  'پست‌ها': ['Posts', 'المنشورات', 'Gönderiler'],
  'نشان آبی': ['Blue badge', 'شارة التوثيق', 'Mavi rozet'],
  'دارد': ['Yes', 'نعم', 'Var'],
  'ندارد': ['No', 'لا', 'Yok'],
  'گفت‌وگوی تازه': ['New conversation', 'محادثة جديدة', 'Yeni sohbet'],
  'پست‌های مرتبط / اخیر': ['Related / recent posts', 'المنشورات ذات الصلة / الأخيرة', 'İlgili / son gönderiler'],
  'پاسخی دریافت نشد.': ['No response was received.', 'لم يتم استلام أي رد.', 'Yanıt alınamadı.'],
  'یک خطای غیرمنتظره رخ داد. دوباره تلاش کن.': ['An unexpected error occurred. Try again.', 'حدث خطأ غير متوقع. حاول مرة أخرى.', 'Beklenmeyen bir hata oluştu. Tekrar dene.'],
  'پرسش کن؛ داده‌ها را شفاف ببین.': ['Ask questions. See the data clearly.', 'اسأل وشاهد البيانات بوضوح.', 'Sor, verileri açıkça gör.'],
  'BinerAI اطلاعات موجود در BinerMention، آمار حساب‌ها و پست‌های عمومی را بررسی می‌کند. این نسخه هنوز جست‌وجوی وب بیرونی ندارد.': ['BinerAI analyzes available BinerMention data, account statistics and public posts. This version does not search the public web yet.', 'يحلل BinerAI بيانات BinerMention المتاحة وإحصاءات الحسابات والمنشورات العامة. لا يدعم هذا الإصدار البحث في الويب الخارجي بعد.', 'BinerAI, BinerMention verilerini, hesap istatistiklerini ve herkese açık gönderileri inceler. Bu sürüm henüz harici web araması yapmaz.'],
  'درباره @hirad990 چه اطلاعاتی در BinerMention ثبت شده؟': ['What information about @hirad990 is available on BinerMention?', 'ما المعلومات المتاحة عن @hirad990 على BinerMention؟', 'BinerMention üzerinde @hirad990 hakkında hangi bilgiler var?'],
  'آخرین پست‌های @hirad990 را نشان بده': ['Show the latest posts by @hirad990', 'اعرض أحدث منشورات @hirad990', '@hirad990 kullanıcısının son gönderilerini göster'],
  'درباره این موضوع چه پست‌هایی منتشر شده؟': ['What posts have been published about this topic?', 'ما المنشورات التي نُشرت حول هذا الموضوع؟', 'Bu konu hakkında hangi gönderiler paylaşıldı?'],
  'در حال بررسی داده‌ها…': ['Analyzing data…', 'جارٍ تحليل البيانات…', 'Veriler inceleniyor…'],
  'از BinerAI چیزی بپرس…': ['Ask BinerAI something…', 'اسأل BinerAI…', 'BinerAI’ye bir şey sor…'],
  'ممنون از اینکه دیدگاهت را به اشتراک گذاشتی.': ['Thanks for sharing your thoughts.', 'شكراً لمشاركة رأيك.', 'Görüşünü paylaştığın için teşekkürler.'],
  'این موضوع ارزش بررسی بیشتری دارد.': ['This topic deserves a closer look.', 'هذا الموضوع يستحق مزيداً من البحث.', 'Bu konu daha yakından incelenmeye değer.'],
  'یک نکتهٔ مهم که نباید فراموش کنیم:': ['One important thing we should not forget:', 'نقطة مهمة يجب ألا ننساها:', 'Unutmamamız gereken önemli bir nokta:'],
  'کپی شد': ['Copied', 'تم النسخ', 'Kopyalandı'],
  'متن': ['Text', 'النص', 'Metin'],
  'اینجا بنویس…': ['Write here…', 'اكتب هنا…', 'Buraya yaz…'],
  'لغو': ['Cancel', 'إلغاء', 'İptal'],
  'انصراف': ['Cancel', 'إلغاء', 'Vazgeç'],
  'ذخیره': ['Save', 'حفظ', 'Kaydet'],
  'گاوصندوق پیش‌نویس‌ها': ['Draft vault', 'مسوداتك', 'Taslak kasası'],
  'پیش‌نویس تازه': ['New draft', 'مسودة جديدة', 'Yeni taslak'],
  'هنوز پیش‌نویسی ذخیره نکردی.': ['You have not saved any drafts yet.', 'لم تحفظ أي مسودات بعد.', 'Henüz taslak kaydetmedin.'],
  'ویرایش پیش‌نویس': ['Edit draft', 'تعديل المسودة', 'Taslağı düzenle'],
  'آزمایشگاه هشتگ': ['Hashtag lab', 'مختبر الوسوم', 'Etiket laboratuvarı'],
  'موضوع یا چند کلمه وارد کن؛ هشتگ‌های پیشنهادی به‌صورت محلی ساخته می‌شوند.': ['Enter a topic or a few words. Suggested hashtags are generated on your device.', 'أدخل موضوعاً أو بضع كلمات. يتم إنشاء الوسوم المقترحة على جهازك.', 'Bir konu veya birkaç kelime gir. Önerilen etiketler cihazında oluşturulur.'],
  'مثلاً برنامه‌نویسی، تکنولوژی، هنر': ['e.g. programming, technology, art', 'مثلاً البرمجة والتقنية والفن', 'ör. programlama, teknoloji, sanat'],
  'ساخت هشتگ': ['Generate hashtags', 'إنشاء وسوم', 'Etiket oluştur'],
  'کپی هشتگ‌ها': ['Copy hashtags', 'نسخ الوسوم', 'Etiketleri kopyala'],
  'کارگاه ویرایش متن': ['Text workshop', 'ورشة تحرير النص', 'Metin atölyesi'],
  'متن را مرتب کن و نسخهٔ تمیزشده را کپی کن.': ['Clean up your text and copy the polished version.', 'نظّم النص وانسخ النسخة المنقحة.', 'Metnini düzenle ve temizlenmiş sürümü kopyala.'],
  'متن خودت را وارد کن…': ['Enter your text…', 'أدخل النص…', 'Metnini gir…'],
  'پاک‌سازی فاصله‌ها': ['Clean spacing', 'تنسيق المسافات', 'Boşlukları düzenle'],
  'فهرست‌سازی': ['Make a list', 'إنشاء قائمة', 'Liste oluştur'],
  'نقل‌قول': ['Quote', 'اقتباس', 'Alıntı'],
  'کپی خروجی': ['Copy output', 'نسخ الناتج', 'Çıktıyı kopyala'],
  'کتابخانهٔ پاسخ‌های آماده': ['Quick replies library', 'مكتبة الردود الجاهزة', 'Hazır yanıt kitaplığı'],
  'افزودن پاسخ آماده': ['Add quick reply', 'إضافة رد جاهز', 'Hazır yanıt ekle'],
  'پاسخ آمادهٔ جدید': ['New quick reply', 'رد جاهز جديد', 'Yeni hazır yanıt'],
  'فیلتر واژه‌های دلخواه': ['Muted words', 'الكلمات المكتومة', 'Sessize alınan kelimeler'],
  'واژه‌هایی که نمی‌خواهی در فید ببینی ذخیره کن. این فهرست آمادهٔ اتصال به فیلتر فید است.': ['Save words you do not want to see in your feed. This list is ready to connect to feed filtering.', 'احفظ الكلمات التي لا تريد رؤيتها في الموجز. هذه القائمة جاهزة للربط بفلتر الموجز.', 'Akışında görmek istemediğin kelimeleri kaydet. Bu liste akış filtresine bağlanmaya hazır.'],
  'یک واژه یا عبارت': ['A word or phrase', 'كلمة أو عبارة', 'Bir kelime veya ifade'],
  'افزودن واژه': ['Add word', 'إضافة كلمة', 'Kelime ekle'],
  'حالت مطالعهٔ متمرکز': ['Focus reading mode', 'وضع القراءة المركزة', 'Odaklı okuma modu'],
  'متن یک پست را اینجا قرار بده تا بدون شلوغی و با خوانایی بیشتر نمایش داده شود.': ['Paste a post here to display it with less clutter and improved readability.', 'الصق منشوراً هنا لعرضه بوضوح أكبر وبدون تشتيت.', 'Daha sade ve okunaklı görüntülemek için bir gönderiyi buraya yapıştır.'],
  'متن پست…': ['Post text…', 'نص المنشور…', 'Gönderi metni…'],
  'شروع مطالعه': ['Start reading', 'ابدأ القراءة', 'Okumaya başla'],
  'استودیوی بیوگرافی': ['Bio studio', 'استوديو النبذة', 'Biyografi stüdyosu'],
  'بیوی کوتاه پروفایلت را بنویس، پیش‌نمایش بگیر و کپی کن.': ['Write a short profile bio, preview it and copy it.', 'اكتب نبذة قصيرة لملفك الشخصي، واعرض معاينتها ثم انسخها.', 'Kısa profil biyografini yaz, önizle ve kopyala.'],
  'علاقه‌مندی‌ها، تخصص‌ها و لینک‌ها…': ['Interests, skills and links…', 'الاهتمامات والمهارات والروابط…', 'İlgi alanları, uzmanlıklar ve bağlantılar…'],
  'پیش‌نمایش پروفایل': ['Profile preview', 'معاينة الملف الشخصي', 'Profil önizlemesi'],
  'بیوی تو اینجا نمایش داده می‌شود.': ['Your bio will appear here.', 'ستظهر نبذتك هنا.', 'Biyografin burada görünecek.'],
  'کپی بیو': ['Copy bio', 'نسخ النبذة', 'Biyografiyi kopyala'],
  'مولد ایدهٔ پست': ['Post idea generator', 'مولّد أفكار المنشورات', 'Gönderi fikri oluşturucu'],
  'برای شروع نوشتن، یک جرقهٔ تازه بگیر.': ['Get a fresh spark to start writing.', 'احصل على فكرة جديدة لبدء الكتابة.', 'Yazmaya başlamak için yeni bir fikir edin.'],
  'ایدهٔ بعدی': ['Next idea', 'الفكرة التالية', 'Sonraki fikir'],
  'کپی ایده': ['Copy idea', 'نسخ الفكرة', 'Fikri kopyala'],
  'برای شروع، یک ایده انتخاب کن.': ['Choose an idea to get started.', 'اختر فكرة للبدء.', 'Başlamak için bir fikir seç.'],
  'برنامه‌ریز رشته‌پست': ['Thread planner', 'مخطط سلاسل المنشورات', 'Dizi gönderi planlayıcı'],
  'یک متن بلند را به بخش‌های حداکثر ۲۸۰ نویسه‌ای تقسیم کن.': ['Split a long text into sections of up to 280 characters.', 'قسّم النص الطويل إلى أجزاء لا تتجاوز 280 حرفاً.', 'Uzun metni en fazla 280 karakterlik bölümlere ayır.'],
  'متن کامل رشته‌پست…': ['Full thread text…', 'نص السلسلة كاملاً…', 'Dizi gönderinin tam metni…'],
  'تقسیم متن': ['Split text', 'تقسيم النص', 'Metni böl'],
  'کپی کل رشته‌پست': ['Copy entire thread', 'نسخ السلسلة كاملة', 'Tüm diziyi kopyala'],
  'بستن': ['Close', 'إغلاق', 'Kapat'],
  'نوشتن را ذخیره کن و بعداً ادامه بده': ['Save your writing and continue later', 'احفظ كتابتك وتابع لاحقاً', 'Yazını kaydet ve daha sonra devam et'],
  'ساخت هشتگ از موضوع و کلیدواژه': ['Create hashtags from a topic and keywords', 'أنشئ وسوماً من موضوع وكلمات مفتاحية', 'Konu ve anahtar kelimelerden etiket oluştur'],
  'پاک‌سازی فاصله، نقل‌قول و فهرست‌سازی': ['Clean spacing, quote and make lists', 'تنسيق المسافات والاقتباس وإنشاء القوائم', 'Boşlukları düzenle, alıntı ve liste oluştur'],
  'کتابخانهٔ پاسخ آماده': ['Quick replies library', 'مكتبة الردود الجاهزة', 'Hazır yanıt kitaplığı'],
  'عبارت‌های پرکاربردت را سریع کپی کن': ['Copy your frequently used phrases quickly', 'انسخ عباراتك المتكررة بسرعة', 'Sık kullandığın ifadeleri hızla kopyala'],
  'فیلتر واژه‌ها': ['Word filter', 'فلتر الكلمات', 'Kelime filtresi'],
  'فهرست واژه‌هایی که نمی‌خواهی ببینی': ['Words you do not want to see', 'الكلمات التي لا تريد رؤيتها', 'Görmek istemediğin kelimeler'],
  'حالت مطالعه': ['Reading mode', 'وضع القراءة', 'Okuma modu'],
  'خواندن متن در محیط خلوت و خوانا': ['Read text in a clean, readable space', 'اقرأ النص في مساحة واضحة وخالية من التشتيت', 'Metni sade ve okunaklı bir alanda oku'],
  'ساخت و پیش‌نمایش بیوی پروفایل': ['Create and preview a profile bio', 'أنشئ نبذة الملف الشخصي واعرض معاينتها', 'Profil biyografisi oluştur ve önizle'],
  'پیشنهاد موضوع برای انتشار بعدی': ['Suggest a topic for your next post', 'اقترح موضوعاً لمنشورك التالي', 'Sonraki paylaşımın için konu öner'],
  'تحلیل‌گر متن': ['Text analyzer', 'محلل النصوص', 'Metin analiz aracı'],
  'آمار نویسه، واژه، هشتگ و زمان مطالعه': ['Character, word, hashtag and reading-time stats', 'إحصاءات الأحرف والكلمات والوسوم ووقت القراءة', 'Karakter, kelime, etiket ve okuma süresi istatistikleri'],
  'تقسیم متن بلند به پست‌های کوتاه': ['Split long text into short posts', 'قسّم النص الطويل إلى منشورات قصيرة', 'Uzun metni kısa gönderilere böl'],
  'آمار زندهٔ نوشته؛ همه‌چیز روی خود دستگاه محاسبه می‌شود.': ['Live writing stats. Everything is calculated on your device.', 'إحصاءات الكتابة مباشرةً. تتم جميع الحسابات على جهازك.', 'Canlı yazı istatistikleri. Her şey cihazında hesaplanır.'],
  'متنت را وارد کن…': ['Enter your text…', 'أدخل النص…', 'Metnini gir…'],
  'نویسه': ['Characters', 'أحرف', 'Karakter'],
  'واژه': ['Words', 'كلمات', 'Kelime'],
  'هشتگ': ['Hashtags', 'وسوم', 'Etiket'],
  'منشن': ['Mentions', 'إشارات', 'Bahsetme'],
  'مطالعه': ['Reading', 'القراءة', 'Okuma'],
  'ایده‌ات را به محتوا تبدیل کن.': ['Turn your ideas into content.', 'حوّل أفكارك إلى محتوى.', 'Fikirlerini içeriğe dönüştür.'],
  '۱۰ ابزار کاربردی برای نوشتن، مدیریت متن و ساخت محتوای بهتر.': ['10 useful tools for writing, text management and better content creation.', '10 أدوات مفيدة للكتابة وإدارة النصوص وإنشاء محتوى أفضل.', 'Yazma, metin yönetimi ve daha iyi içerik üretimi için 10 kullanışlı araç.'],
  'پیش‌نویس': ['Drafts', 'المسودات', 'Taslaklar'],
  'عبارت آماده': ['Quick replies', 'ردود جاهزة', 'Hazır yanıtlar'],
  'فیلتر': ['Filter', 'تصفية', 'Filtre'],
  'ساخت اتاق گفتگو': ['Create chat room', 'إنشاء غرفة محادثة', 'Sohbet odası oluştur'],
  'نام گروه': ['Group name', 'اسم المجموعة', 'Grup adı'],
  'ساخت گروه': ['Create group', 'إنشاء مجموعة', 'Grup oluştur'],
  'ورود به گروه': ['Join group', 'الانضمام إلى المجموعة', 'Gruba katıl'],
  'ورود': ['Sign in', 'تسجيل الدخول', 'Giriş yap'],
  'اتاق‌های گفتگو': ['Chat rooms', 'غرف المحادثة', 'Sohbet odaları'],
  'ورود با لینک': ['Join with link', 'الانضمام عبر رابط', 'Bağlantıyla katıl'],
  'گروه‌ها بارگذاری نشدند': ['Could not load groups', 'تعذر تحميل المجموعات', 'Gruplar yüklenemedi'],
  'اتصال API را بررسی کن و دوباره تلاش کن.': ['Check the API connection and try again.', 'تحقق من اتصال API وحاول مجدداً.', 'API bağlantısını kontrol edip tekrar dene.'],
  'تلاش دوباره': ['Try again', 'حاول مرة أخرى', 'Tekrar dene'],
  'هنوز عضو گروهی نیستی': ['You are not in any groups yet', 'لست عضواً في أي مجموعة بعد', 'Henüz bir gruba üye değilsin'],
  'یک اتاق گفتگو بساز یا با لینک داخلی bm: به گروهی بپیوند.': ['Create a chat room or join a group with a bm: invite link.', 'أنشئ غرفة محادثة أو انضم إلى مجموعة عبر رابط دعوة bm:.', 'Bir sohbet odası oluştur veya bm: davet bağlantısıyla gruba katıl.'],
  'گروه‌های تو': ['Your groups', 'مجموعاتك', 'Grupların'],
  'گفتگوهای گروهی خصوصی و قابل مدیریت': ['Private, manageable group conversations', 'محادثات جماعية خاصة وقابلة للإدارة', 'Özel ve yönetilebilir grup sohbetleri'],
  'گفت‌وگوی تازه': ['New conversation', 'محادثة جديدة', 'Yeni sohbet'],
  'کپی لینک گروه': ['Copy group link', 'نسخ رابط المجموعة', 'Grup bağlantısını kopyala'],
  'لینک گروه کپی شد.': ['Group link copied.', 'تم نسخ رابط المجموعة.', 'Grup bağlantısı kopyalandı.'],
  'بارگذاری پیام‌های گروه انجام نشد.': ['Could not load group messages.', 'تعذر تحميل رسائل المجموعة.', 'Grup mesajları yüklenemedi.'],
  'شناسه رسانه دریافت نشد.': ['Media ID was not returned.', 'لم يتم استلام معرّف الوسائط.', 'Medya kimliği alınamadı.'],
  'ارسال پیام انجام نشد. دوباره تلاش کن.': ['Message could not be sent. Try again.', 'تعذر إرسال الرسالة. حاول مرة أخرى.', 'Mesaj gönderilemedi. Tekrar dene.'],
  'به‌روزرسانی': ['Refresh', 'تحديث', 'Yenile'],
  'پیام‌ها برای اعضای گروه قابل مشاهده‌اند.': ['Messages are visible to group members.', 'الرسائل مرئية لأعضاء المجموعة.', 'Mesajlar grup üyelerine görünür.'],
  'ارسال عکس یا ویدیو': ['Send photo or video', 'إرسال صورة أو فيديو', 'Fotoğraf veya video gönder'],
  'پیام گروه…': ['Message the group…', 'أرسل رسالة إلى المجموعة…', 'Gruba mesaj yaz…'],
  'هنوز داده‌ای ثبت نشده': ['No data recorded yet', 'لم تُسجّل بيانات بعد', 'Henüz veri kaydedilmedi'],
  'کمتر از یک دقیقه': ['Less than a minute', 'أقل من دقيقة', 'Bir dakikadan az'],
  'به‌روزرسانی آمار': ['Refresh statistics', 'تحديث الإحصاءات', 'İstatistikleri yenile'],
  'آمار بارگذاری نشد': ['Could not load statistics', 'تعذر تحميل الإحصاءات', 'İstatistikler yüklenemedi'],
  'اتصال به سرور یا دسترسی API را بررسی کن و دوباره تلاش کن.': ['Check the server connection or API access and try again.', 'تحقق من اتصال الخادم أو الوصول إلى API وحاول مجدداً.', 'Sunucu bağlantısını veya API erişimini kontrol edip tekrar dene.'],
  'پست‌های منتشرشده': ['Published posts', 'المنشورات المنشورة', 'Paylaşılan gönderiler'],
  'لایک دریافتی': ['Likes received', 'الإعجابات المستلمة', 'Alınan beğeniler'],
  'بازنشر دریافتی': ['Reposts received', 'إعادات النشر المستلمة', 'Alınan yeniden paylaşımlar'],
  'کامنت دریافتی': ['Comments received', 'التعليقات المستلمة', 'Alınan yorumlar'],
  'بازدید ثبت‌شده': ['Recorded views', 'المشاهدات المسجلة', 'Kaydedilen görüntülemeler'],
  'نمای کلی حساب': ['Account overview', 'نظرة عامة على الحساب', 'Hesap özeti'],
  'عملکرد حساب': ['Account performance', 'أداء الحساب', 'Hesap performansı'],
  'مجموع داده‌های ثبت‌شده تا این لحظه': ['Total data recorded so far', 'إجمالي البيانات المسجلة حتى الآن', 'Şimdiye kadar kaydedilen toplam veri'],
  'زمان مطالعه': ['Reading time', 'وقت القراءة', 'Okuma süresi'],
  'مجموع زمان تعامل ثبت‌شده با پست‌های عمومی تو': ['Total recorded time spent engaging with your public posts', 'إجمالي وقت التفاعل المسجل مع منشوراتك العامة', 'Herkese açık gönderilerinle kaydedilen toplam etkileşim süresi'],
  'این شاخص از زمان فعال‌شدن ثبت رویدادها معتبر است.': ['This metric is valid from the time event tracking was enabled.', 'هذا المؤشر صالح منذ تفعيل تسجيل الأحداث.', 'Bu ölçüm, olay kaydı etkinleştirildiğinden itibaren geçerlidir.'],
  'پست‌های پربازده': ['Top-performing posts', 'المنشورات الأعلى أداءً', 'En iyi performans gösteren gönderiler'],
  'بر اساس لایک، بازنشر و کامنت': ['Based on likes, reposts and comments', 'استناداً إلى الإعجابات وإعادات النشر والتعليقات', 'Beğeni, yeniden paylaşım ve yorumlara göre'],
  'هنوز دادهٔ کافی نداریم': ['Not enough data yet', 'لا توجد بيانات كافية بعد', 'Henüz yeterli veri yok'],
  'با انتشار پست و دریافت تعامل، این بخش به‌تدریج کامل می‌شود.': ['This section will fill in as you publish posts and receive engagement.', 'سيكتمل هذا القسم تدريجياً عند نشر المنشورات وتلقي التفاعلات.', 'Gönderi paylaşıp etkileşim aldıkça bu bölüm dolacaktır.'],
  'آمار فقط از داده‌های ذخیره‌شده در سامانه محاسبه می‌شود.': ['Statistics are calculated only from data stored in the system.', 'تُحسب الإحصاءات من البيانات المخزنة في النظام فقط.', 'İstatistikler yalnızca sistemde saklanan verilerden hesaplanır.'],
  'پاسخ‌های استوری': ['Story replies', 'ردود القصص', 'Hikâye yanıtları'],
  'دریافت دیدگاه‌ها انجام نشد.': ['Could not load replies.', 'تعذر تحميل الردود.', 'Yanıtlar yüklenemedi.'],
  'هنوز پاسخی ثبت نشده': ['No replies yet', 'لا توجد ردود بعد', 'Henüz yanıt yok'],
  'استوری': ['Story', 'قصة', 'Hikâye'],
  'به این استوری پاسخ بده…': ['Reply to this story…', 'رد على هذه القصة…', 'Bu hikâyeye yanıt ver…'],
  'استوری‌های تو': ['Your stories', 'قصصك', 'Hikâyelerin'],
  'مشاهده استوری‌های من': ['View my stories', 'عرض قصصي', 'Hikâyelerimi gör'],
  'افزودن استوری جدید': ['Add a new story', 'إضافة قصة جديدة', 'Yeni hikâye ekle'],
  'در حال بارگذاری استوری…': ['Uploading story…', 'جارٍ رفع القصة…', 'Hikâye yükleniyor…'],
  'استوری تا ۲۴ ساعت نمایش داده می‌شود.': ['The story will be visible for 24 hours.', 'ستظل القصة ظاهرة لمدة 24 ساعة.', 'Hikâye 24 saat boyunca görünür.'],
  'متن پست کپی شد.': ['Post text copied.', 'تم نسخ نص المنشور.', 'Gönderi metni kopyalandı.'],
  'پستی با این هشتگ پیدا نشد.': ['No posts found with this hashtag.', 'لم يتم العثور على منشورات بهذا الوسم.', 'Bu etiketle gönderi bulunamadı.'],
  'پست جدید': ['New post', 'منشور جديد', 'Yeni gönderi'],
  'چه خبر؟  #هشتگ  @منشن': ['What’s happening?  #hashtag  @mention', 'ما الجديد؟  #وسم  @إشارة', 'Neler oluyor?  #etiket  @bahsetme'],
  'کامنت ثبت شد.': ['Comment posted.', 'تم نشر التعليق.', 'Yorum gönderildi.'],
  'پست ویرایش شد.': ['Post updated.', 'تم تعديل المنشور.', 'Gönderi güncellendi.'],
  'حذف': ['Delete', 'حذف', 'Sil'],
  'پست حذف شد.': ['Post deleted.', 'تم حذف المنشور.', 'Gönderi silindi.'],
  'حساب تأییدشده': ['Verified account', 'حساب موثّق', 'Doğrulanmış hesap'],
  'کامنت‌های این پست': ['Comments on this post', 'التعليقات على هذا المنشور', 'Bu gönderinin yorumları'],
  'کامنت': ['Comment', 'تعليق', 'Yorum'],
  'هنوز کامنتی ثبت نشده؛ اولین نفر باش.': ['No comments yet. Be the first.', 'لا توجد تعليقات بعد. كن أول من يعلّق.', 'Henüz yorum yok. İlk yorumu sen yap.'],
  'حذف پست': ['Delete post', 'حذف المنشور', 'Gönderiyi sil'],
  'حذف از ذخیره‌ها': ['Remove from saved', 'إزالة من المحفوظات', 'Kaydedilenlerden kaldır'],
  'ذخیره پست': ['Save post', 'حفظ المنشور', 'Gönderiyi kaydet'],
  'جست‌وجوی کاربر': ['Search users', 'البحث عن مستخدمين', 'Kullanıcı ara'],
  'ابزارها و تنظیمات': ['Tools and settings', 'الأدوات والإعدادات', 'Araçlar ve ayarlar'],
  'آمار حساب': ['Account insights', 'إحصاءات الحساب', 'Hesap istatistikleri'],
  'حالت روشن': ['Light mode', 'الوضع الفاتح', 'Açık tema'],
  'حالت تیره': ['Dark mode', 'الوضع الداكن', 'Koyu tema'],
  'هنوز پستی وجود ندارد.': ['There are no posts yet.', 'لا توجد منشورات بعد.', 'Henüz gönderi yok.'],
  'اعلان‌ها بارگذاری نشدند': ['Could not load notifications', 'تعذر تحميل الإشعارات', 'Bildirimler yüklenemedi'],
  'اتصال به سرور را بررسی کن و دوباره وارد این بخش شو.': ['Check the server connection and open this section again.', 'تحقق من اتصال الخادم ثم افتح هذا القسم مجدداً.', 'Sunucu bağlantısını kontrol edip bu bölümü yeniden aç.'],
  'اعلان تازه‌ای نداری': ['You have no new notifications', 'ليس لديك إشعارات جديدة', 'Yeni bildirimin yok'],
  'وقتی کسی با پست یا حساب تو تعامل کند، اینجا می‌بینی.': ['When someone interacts with your posts or profile, you will see it here.', 'سترى هنا عندما يتفاعل أحدهم مع منشوراتك أو حسابك.', 'Biri gönderilerinle veya profilinle etkileşime geçtiğinde burada görürsün.'],
  'در یک پست منشن‌ات کرد': ['mentioned you in a post', 'أشار إليك في منشور', 'bir gönderide senden bahsetti'],
  'دنبال‌ات کرد': ['followed you', 'بدأ بمتابعتك', 'seni takip etti'],
  'پستت را پسندید': ['liked your post', 'أعجب بمنشورك', 'gönderini beğendi'],
  'پستت را بازنشر کرد': ['reposted your post', 'أعاد نشر منشورك', 'gönderini yeniden paylaştı'],
  'به پستت پاسخ داد': ['replied to your post', 'رد على منشورك', 'gönderine yanıt verdi'],
  'پیام فرستاد': ['sent you a message', 'أرسل إليك رسالة', 'sana mesaj gönderdi'],
  'استوری‌ات را پسندید': ['liked your story', 'أعجب بقصتك', 'hikâyeni beğendi'],
  'اعلان‌ها': ['Notifications', 'الإشعارات', 'Bildirimler'],
  'آخرین اتفاق‌های مربوط به حساب تو': ['The latest activity related to your account', 'أحدث الأنشطة المتعلقة بحسابك', 'Hesabınla ilgili son etkinlikler'],
  'تعامل جدید': ['New activity', 'تفاعل جديد', 'Yeni etkileşim'],
  'ادامه': ['Continue', 'متابعة', 'Devam et'],
  'پاسخ سرور معتبر نیست.': ['The server response is invalid.', 'استجابة الخادم غير صالحة.', 'Sunucu yanıtı geçersiz.'],
  'پیام‌ها بارگذاری نشدند': ['Could not load messages', 'تعذر تحميل الرسائل', 'Mesajlar yüklenemedi'],
  'وضعیت اتصال و API را بررسی کن.': ['Check the connection and API status.', 'تحقق من الاتصال وحالة API.', 'Bağlantıyı ve API durumunu kontrol et.'],
  'پیام‌ها': ['Messages', 'الرسائل', 'Mesajlar'],
  'گفتگوهای خصوصی و اتاق‌های گروهی': ['Private chats and group rooms', 'المحادثات الخاصة وغرف المجموعات', 'Özel sohbetler ve grup odaları'],
  'اتاق‌های گفتگو': ['Chat rooms', 'غرف المحادثة', 'Sohbet odaları'],
  'پیام جدید': ['New message', 'رسالة جديدة', 'Yeni mesaj'],
  'هنوز گفتگویی نداری': ['No conversations yet', 'لا توجد محادثات بعد', 'Henüz sohbetin yok'],
  'برای شروع یک پیام تازه بساز یا وارد اتاق گفتگو شو.': ['Start by creating a message or joining a chat room.', 'ابدأ بإنشاء رسالة جديدة أو انضم إلى غرفة محادثة.', 'Yeni bir mesaj oluşturarak veya sohbet odasına katılarak başla.'],
  'گفتگو': ['Conversation', 'محادثة', 'Sohbet'],
  'گفتگوی تازه': ['New conversation', 'محادثة جديدة', 'Yeni sohbet'],
  'نام کاربری یا نام نمایشی…': ['Username or display name…', 'اسم المستخدم أو الاسم الظاهر…', 'Kullanıcı adı veya görünen ad…'],
  'برای شروع، حداقل ۲ حرف بنویس.': ['Type at least 2 characters to start.', 'اكتب حرفين على الأقل للبدء.', 'Başlamak için en az 2 karakter yaz.'],
  'کاربری پیدا نشد.': ['No users found.', 'لم يتم العثور على مستخدمين.', 'Kullanıcı bulunamadı.'],
  'ویرایش پروفایل': ['Edit profile', 'تعديل الملف الشخصي', 'Profili düzenle'],
  'پست‌ها': ['Posts', 'المنشورات', 'Gönderiler'],
  'دنبال‌شونده': ['Following', 'المتابَعون', 'Takip edilen'],
  'فونت گوشی': ['System font', 'خط النظام', 'Sistem yazı tipi'],
  'وزیرمتن': ['Vazirmatn', 'وزيرمتن', 'Vazirmatn'],
  'فونت اصلی': ['Default font', 'الخط الافتراضي', 'Varsayılan yazı tipi'],
  'انتخاب عکس پروفایل': ['Choose profile photo', 'اختيار صورة الملف الشخصي', 'Profil fotoğrafı seç'],
  'تغییر عکس انتخاب‌شده': ['Change selected photo', 'تغيير الصورة المحددة', 'Seçili fotoğrafı değiştir'],
  'پروفایل ذخیره شد.': ['Profile saved.', 'تم حفظ الملف الشخصي.', 'Profil kaydedildi.'],
  'به گروه اضافه شدی.': ['You joined the group.', 'لقد انضممت إلى المجموعة.', 'Gruba katıldın.'],
  'دلیل گزارش را بنویس…': ['Write a reason for the report…', 'اكتب سبب الإبلاغ…', 'Şikâyet nedenini yaz…'],
  'گزارش ثبت شد. ممنون که اطلاع دادی.': ['Report submitted. Thanks for letting us know.', 'تم إرسال البلاغ. شكراً لإبلاغنا.', 'Bildirim gönderildi. Bize haber verdiğin için teşekkürler.'],
  'پس از مسدودسازی، ارسال پیام در این گفت‌وگو متوقف می‌شود.': ['After blocking, messaging in this conversation will stop.', 'بعد الحظر، سيتوقف إرسال الرسائل في هذه المحادثة.', 'Engelledikten sonra bu sohbette mesajlaşma durur.'],
  'کاربر مسدود شد.': ['User blocked.', 'تم حظر المستخدم.', 'Kullanıcı engellendi.'],
  'متنی برای پردازش وجود ندارد.': ['There is no text to process.', 'لا يوجد نص لمعالجته.', 'İşlenecek metin yok.'],
  'متن پیام کپی شد.': ['Message copied.', 'تم نسخ الرسالة.', 'Mesaj kopyalandı.'],
  'انتخاب مقصد بازارسال': ['Choose a forwarding destination', 'اختر وجهة إعادة التوجيه', 'İletme hedefini seç'],
  'گزارش گفت‌وگو': ['Report conversation', 'الإبلاغ عن المحادثة', 'Sohbeti bildir'],
  'مسدود کردن کاربر': ['Block user', 'حظر المستخدم', 'Kullanıcıyı engelle'],
  'رسانه': ['Media', 'الوسائط', 'Medya'],
  'سرعت پخش': ['Playback speed', 'سرعة التشغيل', 'Oynatma hızı'],
  'پخش ویدیو ممکن نشد.': ['Video could not be played.', 'تعذر تشغيل الفيديو.', 'Video oynatılamadı.'],
  'بارگذاری پروفایل انجام نشد.': ['Could not load profile.', 'تعذر تحميل الملف الشخصي.', 'Profil yüklenemedi.'],
  'هنوز کسی اینجا نیست.': ['No one is here yet.', 'لا يوجد أحد هنا بعد.', 'Burada henüz kimse yok.'],
  'هنوز پستی منتشر نشده.': ['No posts have been published yet.', 'لم يتم نشر أي منشورات بعد.', 'Henüz gönderi paylaşılmadı.'],
  'بازگشت': ['Back', 'رجوع', 'Geri'],
  'اتصال به سرور برقرار نشد. اینترنت و وضعیت API را بررسی کن.': ['Could not connect to the server. Check your internet and API status.', 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحالة API.', 'Sunucuya bağlanılamadı. İnternetini ve API durumunu kontrol et.'],
  'سرور موقتاً در دسترس نیست.': ['The server is temporarily unavailable.', 'الخادم غير متاح مؤقتاً.', 'Sunucu geçici olarak kullanılamıyor.'],
  'درخواست انجام نشد.': ['The request failed.', 'فشل الطلب.', 'İstek başarısız oldu.'],
  'سرور توکن ورود را برنگرداند.': ['The server did not return a sign-in token.', 'لم يُرجع الخادم رمز تسجيل الدخول.', 'Sunucu giriş belirtecini döndürmedi.'],
  'برای بارگذاری فایل وارد حساب شو.': ['Sign in to upload a file.', 'سجّل الدخول لرفع ملف.', 'Dosya yüklemek için giriş yap.'],
  'فایل انتخاب‌شده خالی است.': ['The selected file is empty.', 'الملف المحدد فارغ.', 'Seçilen dosya boş.'],
  'بارگذاری فایل انجام نشد.': ['File upload failed.', 'فشل رفع الملف.', 'Dosya yüklenemedi.'],
  'بارگذاری فایل ناموفق بود؛ اتصال و محدودیت آپلود سرور را بررسی کن.': ['Upload failed. Check your connection and the server upload limits.', 'فشل الرفع. تحقق من الاتصال وحدود الرفع على الخادم.', 'Yükleme başarısız. Bağlantını ve sunucu yükleme sınırlarını kontrol et.'],
  'سرور شناسه گفت‌وگو را برنگرداند.': ['The server did not return a conversation ID.', 'لم يُرجع الخادم معرّف المحادثة.', 'Sunucu sohbet kimliğini döndürmedi.'],
  'سرویس ترجمه در دسترس نیست.': ['Translation service is unavailable.', 'خدمة الترجمة غير متاحة.', 'Çeviri hizmeti kullanılamıyor.'],
  'ترجمه‌ای دریافت نشد.': ['No translation was received.', 'لم يتم استلام ترجمة.', 'Çeviri alınamadı.'],
};

String? _translateDynamicUiText(String value, String language) {
  final patterns = <RegExp, List<String>>{
    RegExp(r'^([0-9]+) دقیقه'): ['%1 min', '%1 دقيقة', '%1 dk'],
    RegExp(r'^([0-9]+) ساعت و ([0-9]+) دقیقه'): ['%1 hr %2 min', '%1 ساعة و%2 دقيقة', '%1 sa %2 dk'],
    RegExp(r'^([0-9]+) ساعت'): ['%1 hr', '%1 ساعة', '%1 sa'],
    RegExp(r'^([0-9]+) نویسه'): ['%1 characters', '%1 حرفاً', '%1 karakter'],
    RegExp(r'^([0-9]+) بخش آماده شد'): ['%1 sections ready', 'تم تجهيز %1 أجزاء', '%1 bölüm hazır'],
    RegExp(r'^بخش ([0-9]+) · ([0-9]+)/280'): ['Part %1 · %2/280', 'الجزء %1 · %2/280', 'Bölüm %1 · %2/280'],
    RegExp(r'^([0-9]+) پیام اخیر'): ['%1 recent messages', '%1 رسالة حديثة', '%1 son mesaj'],
    RegExp(r'^([0-9]+) عضو  ·  (.*)'): ['%1 members · %2', '%1 أعضاء · %2', '%1 üye · %2'],
    RegExp(r'^پست (.+)'): ['Post by %1', 'منشور بواسطة %1', '%1 kullanıcısının gönderisi'],
    RegExp(r'^(.+) واژه · حدود ([0-9]+) دقیقه مطالعه'): ['%1 words · about %2 min read', '%1 كلمة · نحو %2 دقيقة قراءة', '%1 kelime · yaklaşık %2 dk okuma'],
  };
  for (final entry in patterns.entries) {
    final match = entry.key.firstMatch(value);
    if (match == null || match.group(0) != value) continue;
    var translated = entry.value[language == 'ar' ? 1 : language == 'tr' ? 2 : 0];
    for (var i = 1; i <= match.groupCount; i++) {
      translated = translated.replaceAll('%$i', match.group(i) ?? '');
    }
    return translated;
  }
  return null;
}

String binerText(String fa, {String? en, String? ar, String? tr}) {
  final language = BinerPreferences.instance.locale.languageCode;
  if (language == 'fa') return fa;
  final translations = _uiTranslations[fa];
  final dynamicTranslation = _translateDynamicUiText(fa, language);
  switch (language) {
    case 'en':
      return en ?? translations?[0] ?? dynamicTranslation ?? fa;
    case 'ar':
      return ar ?? translations?[1] ?? dynamicTranslation ?? en ?? translations?[0] ?? fa;
    case 'tr':
      return tr ?? translations?[2] ?? dynamicTranslation ?? en ?? translations?[0] ?? fa;
    default:
      return fa;
  }
}
