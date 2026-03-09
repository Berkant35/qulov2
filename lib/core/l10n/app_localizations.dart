import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late final Map<String, String> _strings;

  AppLocalizations(this.locale) {
    _strings = _localizedValues[locale.languageCode] ?? _localizedValues['tr']!;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get(String key) => _strings[key] ?? key;

  String errorMessage(String code) {
    final key = 'error_${code.toLowerCase()}';
    return _strings[key] ?? _strings['error_unknown']!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'tr': _tr,
    'en': _en,
  };

  static const _tr = <String, String>{
    // General
    'app_name': 'Qulo',
    'ok': 'Tamam',
    'cancel': 'İptal',
    'save': 'Kaydet',
    'delete': 'Sil',
    'loading': 'Yükleniyor...',
    'error': 'Hata',
    'success': 'Başarılı',
    'retry': 'Tekrar Dene',
    'rotate': 'Döndür',
    'yes': 'Evet',
    'no': 'Hayır',

    // Auth
    'welcome_back': 'Tekrar hoş geldin',
    'login': 'Giriş Yap',
    'register': 'Kayıt Ol',
    'email': 'E-posta',
    'password': 'Şifre',
    'forgot_password': 'Şifremi unuttum?',
    'no_account': 'Hesabın yok mu?',
    'reset_password': 'Şifre Sıfırla',
    'reset_password_desc': 'E-posta adresini gir, sıfırlama bağlantısı gönderelim.',
    'send_reset_link': 'Sıfırlama Bağlantısı Gönder',
    'reset_email_sent': 'E-posta adresin kayıtlıysa sıfırlama bağlantısı gönderildi',
    'check_email': 'E-postanı kontrol et ve doğrula',
    'name': 'Ad',
    'surname': 'Soyad',
    'age': 'Yaş',
    'gender': 'Cinsiyet',
    'male': 'Erkek',
    'female': 'Kadın',

    // Validation
    'field_required': 'Bu alan zorunlu',
    'email_required': 'E-posta zorunlu',
    'email_invalid': 'Geçersiz e-posta',
    'password_required': 'Şifre zorunlu',
    'password_min': 'En az 8 karakter',
    'age_range': '18-99 arası',

    // Onboarding
    'onboarding_title_1': "Qulo'ya Hoş Geldin",
    'onboarding_sub_1': 'Soruları cevaplayarak eşleşme bul',
    'onboarding_title_2': 'Sorularını Hazırla',
    'onboarding_sub_2': 'Seninle eşleşmek isteyenler için 2-6 soru oluştur',
    'onboarding_title_3': 'Profilini Tamamla',
    'onboarding_sub_3': 'Fotoğraf ve bilgilerini ekleyerek öne çık',
    'next': 'İleri',
    'skip': 'Atla',
    'get_started': 'Başla',

    // Discover
    'discover': 'Keşfet',
    'no_more_profiles': 'Gösterilecek profil kalmadı',
    'refresh': 'Yenile',
    'questions_count': '{count} soru',

    // Quiz
    'quiz_match': 'Eşleşme!',
    'quiz_match_desc': 'Tüm soruları doğru cevapladın!',
    'quiz_failed': 'Başarısız',
    'quiz_failed_desc': 'Yanlış cevap. Bir dahaki sefere!',

    // Matches
    'matches': 'Eşleşmeler',
    'no_matches': 'Henüz eşleşme yok',
    'start_swiping': 'Eşleşme bulmak için keşfetmeye başla!',

    // Chat
    'chat': 'Sohbet',
    'say_hello': 'Merhaba de!',
    'message_hint': 'Mesaj...',
    'type_message': 'Mesaj yaz...',

    // Matches extras
    'new_matches': 'Yeni Eslesmeler',
    'solve_to_meet': 'Sorulari Coz',
    'online': 'Cevrimici',
    'offline': 'Cevrimdisi',

    // Profile
    'profile': 'Profil',
    'edit_profile': 'Profili Düzenle',
    'my_questions': 'Sorularım',
    'diamonds': 'Elmaslar',
    'passport': 'Pasaport',
    'complete': 'tamamlandı',

    // Questions
    'add_question': 'Yeni Soru',
    'question': 'Soru',
    'answer_n': 'Cevap {n}',
    'correct_answer': 'Doğru Cevap',
    'min_questions': 'En az {count} soru ekle',
    'max_questions': 'En fazla 6 soru',

    // Diamonds
    'green_diamonds': 'Yeşil Elmaslar',
    'purple_diamonds': 'Mor Elmaslar',
    'purchase_purple': 'Mor Elmas Paketleri',
    'history': 'İşlem Geçmişi',
    'no_transactions': 'Henüz işlem yok',
    'see_all': 'Tümü',
    'best_value': 'En Avantajlı',
    'premium_cta': "Qulo Premium'a geç!",
    'premium_benefits': 'Sınırsız kaydırma, geri alma ve aylık mor elmas bonusu',
    'view_plans': 'Planları Gör',
    'active_plan': 'Aktif Plan',
    'expires_at': 'Bitiş: {date}',
    'your_balance': 'Bakiyen',
    'failed_load_balance': 'Bakiye yüklenemedi',

    // Passport
    'passport_explore': 'Başka bir şehirdeki profilleri keşfet',
    'passport_cost': 'Maliyet: {cost} mor elmas / aktivasyon',
    'passport_active': 'Aktif: {city}',
    'city': 'Şehir',
    'activate_passport': 'Pasaportu Aktifleştir',
    'deactivate': 'Deaktif Et',
    'passport_premium_only': 'Pasaport modu Premium üyelere özeldir',
    'passport_premium_desc': 'Premium\'a yükselerek istediğin şehirden eşleşmeleri keşfet',
    'passport_pick_on_map': 'Haritadan Konum Seç',
    'passport_select_location': 'Konumu seçmek için haritayı kaydır',
    'passport_move_here': 'Buraya Taşın',
    'passport_active_desc': 'Keşif bu konumdan yapılıyor',
    'passport_deactivate': 'Gerçek Konumuma Dön',
    'passport_change_city': 'Farklı bir şehre taşın',
    'passport_explore_hint': 'Pasaport ile başka şehirleri keşfet',
    'passport_premium_explore_hint': 'Premium ile başka şehirleri keşfet',
    'upgrade_to_premium': 'Premium\'a Yükselt',

    // Discover Empty State
    'no_more_profiles_hint': 'Mesafe aralığını artırarak daha fazla kişi görebilirsin',
    'match_radius': 'Eşleşme Mesafesi',
    'search_again': 'Yeniden Ara',

    // Location
    'location_required': 'Konum izni gerekli',
    'location_required_desc': 'Yakınındaki kişileri görebilmek için konum iznini etkinleştir',

    // Settings
    'settings': 'Ayarlar',
    'language': 'Dil',
    'theme': 'Tema',
    'theme_system': 'Sistem',
    'theme_light': 'Acik',
    'theme_dark': 'Koyu',
    'logout': 'Çıkış Yap',
    'logout_confirm': 'Çıkış yapmak istediğine emin misin?',
    'delete_account': 'Hesabı Sil',
    'delete_account_desc': 'Bu işlem geri alınamaz. Tüm verilerin silinecek.',

    // Powers
    'power_copy': 'Kopya',
    'power_half': '50/50',
    'power_skip': 'Geç',
    'power_hint': 'İpucu',
    'power_time': '+15sn',
    'power_skip_all': 'Hepsini Geç',

    // Error codes
    'error_invalid_credentials': 'Email veya şifre hatalı',
    'error_email_already_exists': 'Bu email zaten kayıtlı',
    'error_email_not_verified': 'Lütfen önce emailinizi doğrulayın',
    'error_validation_error': 'Lütfen girişlerinizi kontrol edin',
    'error_rate_limited': 'Çok fazla deneme, lütfen daha sonra tekrar deneyin',
    'error_server_error': 'Bir hata oluştu, lütfen tekrar deneyin',
    'error_unknown': 'Beklenmeyen bir hata oluştu',

    // Register wizard
    'step_name': 'Adın ne?',
    'step_birthday': 'Doğum günün ne zaman?',
    'step_gender': 'Cinsiyetin ne?',
    'step_email': 'Hesabını oluştur',
    'step_terms': 'Neredeyse tamam!',
    'birthday': 'Doğum tarihi',
    'select_date': 'Tarih seçin',
    'must_be_18': 'En az 18 yaşında olmalısınız',
    'man': 'Erkek',
    'woman': 'Kadın',
    'other': 'Diğer',
    'continue_btn': 'Devam',
    'accept_terms': 'Kabul ediyorum:',
    'terms_of_service': 'Kullanım Koşulları',
    'privacy_policy': 'Gizlilik Politikası',
    'and_word': 've',
    'must_accept_terms': 'Devam etmek için koşulları kabul etmelisiniz',

    // Location step
    'step_location': 'Konumunu paylaş',
    'step_location_desc':
        'Yakınındaki kişilerle eşleşebilmemiz için konumuna ihtiyacımız var.',
    'enable_location': 'Konumu Etkinleştir',
    'location_granted': 'Konum alındı',
    'location_skip': 'Şimdilik atla',
    'location_service_disabled': 'Konum servisleri kapalı. Lütfen ayarlardan açın.',
    'location_permission_denied': 'Konum izni reddedildi.',
    'location_permission_denied_forever':
        'Konum izni kalıcı olarak reddedildi. Ayarlardan etkinleştirin.',
    'open_settings': 'Ayarları Aç',

    // Profile - Badge
    'badge_rookie': 'Çaylak',
    'badge_popular': 'Popüler',
    'badge_master': 'Profil Ustası',
    'badge_no_badge': 'Başlangıç',
    'badge_progress_hint': 'kaldı',
    'badge_reward_claimed': 'Tebrikler! Mor elmas kazandın!',
    'badge_claim_reward': 'Ödülü Al',
    'badge_discover_warning': 'Profilini tamamla, keşfette görün!',

    // Profile - Hints
    'hint_add_photos': '3 fotoğraf ekle → görünürlüğün %20 artar!',
    'hint_add_bio': 'Bio ekle → daha fazla eşleşme!',
    'hint_add_job': 'Mesleğini ekle → profilini tamamla!',
    'hint_add_details': 'Detaylarını ekle → profil seviyeni yükselt!',

    // Profile - Edit
    'edit_photos': 'Fotoğraflar',
    'edit_about': 'Hakkımda',
    'edit_basic_info': 'Temel Bilgiler',
    'edit_details': 'Detaylar',
    'edit_preferences': 'Tercihler',
    'save_changes': 'Değişiklikleri Kaydet',
    'bio_hint': 'Kendinden biraz bahset...',
    'city_hint': 'Hangi şehirde yaşıyorsun?',
    'job_hint': 'Ne iş yapıyorsun?',
    'school_hint': 'Hangi okulu bitirdin?',
    'pets_hint': 'Evcil hayvanın var mı?',
    'music_hint': 'En sevdiğin müzik türü?',
    'personality_hint': 'Kendini nasıl tanımlarsın?',
    'update_location': 'Konumu Güncelle',
    'make_primary': 'Ana Fotoğraf Yap',
    'delete_photo': 'Fotoğrafı Sil',
    'delete_photo_confirm': 'Bu fotoğrafı silmek istediğine emin misin?',
    'photo_upload_error': 'Fotoğraf yüklenemedi',
    'photo_max_reached': 'En fazla 6 fotoğraf ekleyebilirsin',
    'changes_saved': 'Değişiklikler kaydedildi',
    'select_photo_source': 'Fotoğraf Kaynağı',
    'from_gallery': 'Galeriden Seç',
    'from_camera': 'Kamera',

    // Details labels
    'height': 'Boy',
    'weight': 'Kilo',
    'zodiac': 'Burç',
    'job': 'Meslek',
    'school': 'Okul',
    'smoking': 'Sigara',
    'alcohol': 'Alkol',
    'pets_label': 'Evcil Hayvan',
    'music_type': 'Müzik Türü',
    'personality': 'Kişilik',
    'cm': 'cm',
    'kg': 'kg',

    // Preferences
    'gender_preference': 'Cinsiyet Tercihi',
    'distance_range': 'Mesafe',
    'km': 'km',
    'men': 'Erkek',
    'women': 'Kadın',
    'both': 'Herkes',

    // Zodiac signs
    'zodiac_aries': 'Koç',
    'zodiac_taurus': 'Boğa',
    'zodiac_gemini': 'İkizler',
    'zodiac_cancer': 'Yengeç',
    'zodiac_leo': 'Aslan',
    'zodiac_virgo': 'Başak',
    'zodiac_libra': 'Terazi',
    'zodiac_scorpio': 'Akrep',
    'zodiac_sagittarius': 'Yay',
    'zodiac_capricorn': 'Oğlak',
    'zodiac_aquarius': 'Kova',
    'zodiac_pisces': 'Balık',

    // Subscription
    'sub_choose_plan': 'Planını Seç',
    'sub_plan_free': 'Ücretsiz',
    'sub_plan_plus': 'Qulo Plus',
    'sub_plan_premium': 'Qulo Premium',
    'sub_price_free': 'Ücretsiz',
    'sub_price_plus': '\$4.99/ay',
    'sub_price_premium': '\$9.99/ay',
    'sub_recommended': 'ÖNERİLEN',
    'sub_current_plan': 'Mevcut Plan',
    'sub_restore_purchases': 'Satın Almaları Geri Yükle',
    'sub_purchase_coming_soon': 'Satın alma yakında aktif olacak',
    'sub_restore_done': 'Satın almalar geri yüklendi',
    'sub_free_discovers': '50 keşif/gün',
    'sub_free_questions': '4 soru slotu',
    'sub_free_ads': 'Reklam var',
    'sub_plus_discovers': 'Sınırsız keşif',
    'sub_plus_questions': '6 soru slotu',
    'sub_plus_diamonds': '500 mor elmas/ay',
    'sub_plus_undos': '3 geri alma/gün',
    'sub_plus_no_ads': 'Reklam yok',
    'sub_premium_discovers': 'Sınırsız keşif',
    'sub_premium_questions': '10 soru slotu',
    'sub_premium_diamonds': '1500 mor elmas/ay',
    'sub_premium_undos': 'Sınırsız geri alma',
    'sub_premium_passport': 'Pasaport modu',
    'sub_premium_no_ads': 'Reklam yok',

    'purchase_success': 'Satın alma başarılı!',
    'purchase_failed': 'Satın alma başarısız oldu',

    // Upsell
    'diamonds_empty': 'Elmasların bitti!',
    'swipe_limit_reached': 'Bugünlük swipe hakkın doldu',
    'first_match_congrats': 'Tebrikler, ilk eşleşmen!',
    'want_more_matches': 'Daha fazla eşleşme ister misin?',
    'special_offer': 'Özel Teklif',
    'limited_time': 'Sınırlı süre',
    'upgrade_now': 'Şimdi Yükselt',
    'get_diamonds': 'Elmas Al',
    'maybe_later': 'Belki sonra',
    'unlock_unlimited': 'Sınırsız erişimin kilidini aç',

    // Frequency
    'freq_yes': 'Evet',
    'freq_no': 'Hayır',
    'freq_sometimes': 'Bazen',

    // Discover & Matches (i18n cleanup)
    'solve_questions': 'Soruları Çöz',
    'unknown_user': 'Bilinmeyen',

    // Question Gate & Nudge
    'question_nudge_title': 'Keşfedilmek için sorularını ekle!',
    'question_nudge_subtitle': 'Profilin %{percent} hazır — sadece sorular eksik!',
    'question_nudge_progress': '{count}/2 soru',
    'question_nudge_add_button': 'Sorularımı Ekle',
    'question_nudge_edit_hint': 'Profilini düzenlemek harika! Eşleşmelerde görünmek için en az 2 soru eklemeyi unutma.',
    'question_nudge_go_questions': 'Sorularıma Git',
    'question_nudge_discover_locked': 'Sorularını ekle, keşfetmeye başla!',
    'question_nudge_celebration_title': 'Tebrikler! Artık keşfedilebilirsin!',
    'question_nudge_celebration_button': 'Keşfetmeye Başla',
    'question_nudge_menu_required': '2 soru gerekli',

    // Notifications
    'notifications': 'Bildirimler',
    'mark_all_read': 'Tümünü Okundu Yap',
    'no_notifications': 'Henüz bildirim yok',
    'just_now': 'Az önce',
    'minutes_ago': '{} dk önce',
    'hours_ago': '{} saat önce',
    'days_ago': '{} gün önce',

    // Version & Update
    'update_required_title': 'Güncelleme Gerekli',
    'update_required_message': 'Uygulamayı kullanmaya devam etmek için lütfen güncelleyin.',
    'update_available_title': 'Yeni Güncelleme Mevcut',
    'update_available_message': 'Daha iyi bir deneyim için uygulamayı güncelleyin.',
    'update_button': 'Güncelle',
    'update_later': 'Daha Sonra',
    'maintenance_title': 'Bakım Çalışması',
    'maintenance_default_message': 'Uygulama şu anda bakımdadır. Lütfen daha sonra tekrar deneyin.',

    // Question Creation
    'question_create_title': 'Soru Oluştur',
    'question_edit_title': 'Soruyu Düzenle',
    'question_create_easy_mode': 'Kolay Mod',
    'question_create_advanced_mode': 'Gelişmiş Mod',
    'question_create_step_question': 'Soruyu Yaz',
    'question_create_step_answers': 'Şıkları Gir',
    'question_create_step_settings': 'Ayarlar',
    'question_create_motto': 'Seni anlatan sorular sor — cevabı Google\'da bulunmasın',
    'question_create_motto_tip': 'İpucu: "En sevdiğim mevsim?" gibi kişisel sorular daha çok çözülür',
    'question_create_select_category': 'Kategori Seç',
    'question_create_select_time': 'Süre Seç',
    'question_create_hint_label': 'İpucu (opsiyonel)',
    'question_create_preview': 'Önizleme',
    'question_create_save': 'Kaydet',
    'question_create_update': 'Güncelle',

    // Categories
    'question_category_personality': 'Kişilik',
    'question_category_music': 'Müzik',
    'question_category_film': 'Film',
    'question_category_sports': 'Spor',
    'question_category_travel': 'Seyahat',
    'question_category_food': 'Yemek',
    'question_category_technology': 'Teknoloji',
    'question_category_general': 'Genel',
    'question_category_other': 'Diğer',

    // Time Presets
    'question_time_fast': 'Hızlı',
    'question_time_fast_desc': 'Düşünme, hisset!',
    'question_time_normal': 'Normal',
    'question_time_normal_desc': 'Standart tempo',
    'question_time_relaxed': 'Rahat',
    'question_time_relaxed_desc': 'Düşünmeye zaman var',
    'question_time_thoughtful': 'Düşündürücü',
    'question_time_thoughtful_desc': 'Zor soru hak eder',

    // AI Suggestions
    'ai_suggest_title': 'AI Soru Önerileri',
    'ai_suggest_category': 'Kategoriye göre öner',
    'ai_suggest_profile': 'Profilime göre öner',
    'ai_suggest_loading': 'Sorular hazırlanıyor...',
    'ai_suggest_select': 'Bu Soruyu Seç',
    'ai_suggest_empty': 'Öneri bulunamadı, tekrar deneyin',

    // Analytics
    'analytics_title': 'Soru İstatistikleri',
    'analytics_total_solves': 'Toplam Çözülme',
    'analytics_success_rate': 'Başarı Oranı',
    'analytics_green_earned': 'Kazanılan Yeşil Elmas',
    'analytics_best_question': 'En İyi Sorun',
    'analytics_difficulty_easy': 'Kolay',
    'analytics_difficulty_medium': 'Orta',
    'analytics_difficulty_hard': 'Zor',
    'analytics_difficulty_legendary': 'Efsanevi',
    'analytics_difficulty_unranked': 'Sıralanmadı',
    'analytics_avg_time': 'Ort. Süre',
    'analytics_power_usage': 'Güç Kullanımı',
    'analytics_answer_distribution': 'Cevap Dağılımı',
    'analytics_min_solves': 'Rozet için en az 10 çözülme gerekli',
    'analytics_correct': 'Doğru',
    'analytics_wrong': 'Yanlış',
    'analytics_question_num': 'Soru #{n}',
    'analytics_green_question': 'Bu soru sana {n} yeşil elmas kazandırdı',
    'analytics_no_data': 'Henüz istatistik yok',
    'analytics_seconds': '{n}s',
    'analytics_answer_n': 'Cevap {n}',

    // Pending Changes
    'pending_changes_title': 'Bekleyen İşlemler',
    'pending_change_update': 'Düzenleme bekliyor',
    'pending_change_delete': 'Silme bekliyor',
    'pending_change_cancel': 'İptal Et',
    'pending_change_applied': 'Değişiklik uygulandı',
    'pending_change_info': 'Aktif quiz olduğu için değişiklik kuyruğa alındı',

    // Quiz Result
    'quiz_result_flawless': 'Kusursuz',
    'quiz_result_speed_solver': 'Hızlı Çözücü',
    'quiz_result_power_master': 'Güç Ustası',
    'quiz_result_determined': 'Azimli',
    'quiz_result_time_spent': 'Harcanan Süre',
    'quiz_result_powers_used': 'Kullanılan Güçler',
    'quiz_result_matched': 'Eşleştin!',
    'quiz_result_not_matched': 'Bu sefer olmadı',
    'quiz_result_correct_count': '{correct}/{total} doğru',
    'quiz_result_start_chat': 'Sohbete Başla',
    'quiz_result_go_back': 'Geri Dön',

    // Chat Quiz Summary
    'chat_quiz_summary': 'Quiz Özeti',
    'chat_quiz_summary_solved': '{count} soruyu {time}sn\'de çözdü',

    // Discover Card
    'discover_questions_count': '{count} soru',
    'discover_difficulty': 'Zorluk',

    // Weekly Report
    'weekly_report_title': 'Haftalık Rapor',
    'weekly_report_solves': 'Bu hafta soruların {count} kez çözüldü',
    'weekly_report_green': '{count} yeşil elmas kazandın',

    // Onboarding - Questions
    'onboarding_questions_slide1_title': 'Soru Hazırla, Eşleş!',
    'onboarding_questions_slide1_desc': 'Qulo\'da eşleşmek için sorularını hazırla. Birisi tüm sorularını doğru cevaplarsa eşleşirsiniz!',
    'onboarding_questions_slide2_title': 'Seni Anlatan Sorular',
    'onboarding_questions_slide2_desc': 'Google\'da bulunamayacak, sana özel sorular sor. "Favori yemeğim nedir?" gibi kişisel sorular daha eğlenceli!',
    'onboarding_questions_slide3_title': 'Yeşil Elmas Kazan!',
    'onboarding_questions_slide3_desc': 'Birisi sorularını çözerken güç kullanırsa, harcadığı mor elmasın %30\'u sana yeşil elmas olarak gelir!',
    'onboarding_questions_start': 'Hemen Başla',
    'onboarding_questions_later': 'Sonra',

    // Profile Vitrin
    'profile_vitrin_solves': 'kez çözüldü',
    'profile_vitrin_success': 'başarı oranı',
    'profile_vitrin_green': 'kazanıldı',
    'profile_vitrin_title': 'Soru İstatistiklerin',

    // Mode Selection
    'question_mode_title': 'Nasıl oluşturmak istersin?',
    'question_mode_easy_desc': 'AI sana soru önersin, sen seç',
    'question_mode_advanced_desc': 'Adım adım kendin oluştur',

    // Progressive Nudge
    'nudge_easy_mode_hint': 'Kolay mod ile 30 saniyede soru hazırla!',
    'nudge_easy_mode_button': 'Kolay Mod ile Başla',
    'nudge_quick_create_title': 'Hızlı Soru Oluştur',
    'nudge_profile_suggest': 'Profilime göre öner',

    // Subscription celebration
    'celebration_title_plus': 'Qulo Plus\'a hoş geldin!',
    'celebration_title_premium': 'Qulo Premium\'a hoş geldin!',
    'celebration_diamonds_plus': '+500 Mor Elmas',
    'celebration_diamonds_premium': '+1500 Mor Elmas',
    'celebration_diamonds_desc': 'Aylık bonusun hesabına eklendi',
    'celebration_button': 'Harika!',

    // Subscription profile
    'sub_my_subscription': 'Aboneliğim',
    'sub_free_upgrade': 'Ücretsiz Plan • Yükselt',

    // Monthly benefits
    'monthly_benefits_title': 'Haklarım',
    'benefit_daily_discovers': 'Günlük Keşif',
    'benefit_daily_undos': 'Günlük Geri Alma',
    'benefit_question_slots': 'Soru Slotu',
    'benefit_monthly_diamonds': 'Aylık Elmas',
    'benefit_passport': 'Pasaport Modu',
    'benefit_ads': 'Reklamlar',
    'benefit_unlimited': 'Sınırsız',
    'benefit_given': 'Verildi',
    'benefit_active': 'Aktif',
    'benefit_inactive': 'Kapalı',
    'benefit_none': 'Yok',
    'benefit_no_ads': 'Reklam Yok',
    'benefit_has_ads': 'Reklam Var',

    // Language system
    'question_language': 'Soru dili',
    'language_picker_title': 'Hangi dillerde soru \u00e7\u00f6zebilirsin?',
    'language_picker_select_one': 'Soru dilini se\u00e7',
    'language_picker_hint': 'En az bir dil se\u00e7ili olmal\u0131',
    'settings_question_languages': 'Soru Dilleri',
    'settings_question_languages_none': 'Hen\u00fcz dil se\u00e7ilmedi',
    'onboarding_questions_slide4_title': 'Hangi Dilleri Biliyorsun?',
    'onboarding_questions_slide4_desc': 'Sana uygun dillerdeki profilleri g\u00f6sterelim. Birden fazla se\u00e7ebilirsin!',
    // Locale names
    'locale_tr': 'T\u00fcrk\u00e7e',
    'locale_en': 'English',
    'locale_de': 'Deutsch',
    'locale_fr': 'Fran\u00e7ais',
    'locale_es': 'Espa\u00f1ol',
    'locale_ar': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    'locale_ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    'locale_pt': 'Portugu\u00eas',
    'locale_it': 'Italiano',
    'locale_ja': '\u65e5\u672c\u8a9e',
    'locale_ko': '\ud55c\uad6d\uc5b4',
    'locale_zh': '\u4e2d\u6587',
    'locale_nl': 'Nederlands',
    'locale_pl': 'Polski',
    'locale_sv': 'Svenska',
  };

  static const _en = <String, String>{
    // General
    'app_name': 'Qulo',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    'rotate': 'Rotate',
    'yes': 'Yes',
    'no': 'No',

    // Auth
    'welcome_back': 'Welcome back',
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'no_account': "Don't have an account?",
    'reset_password': 'Reset Password',
    'reset_password_desc': 'Enter your email address and we will send you a link to reset your password.',
    'send_reset_link': 'Send Reset Link',
    'reset_email_sent': 'If your email exists, you will receive a reset link',
    'check_email': 'Check your email to verify',
    'name': 'Name',
    'surname': 'Surname',
    'age': 'Age',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',

    // Validation
    'field_required': 'This field is required',
    'email_required': 'Email is required',
    'email_invalid': 'Invalid email',
    'password_required': 'Password is required',
    'password_min': 'Min 8 characters',
    'age_range': '18-99',

    // Onboarding
    'onboarding_title_1': 'Welcome to Qulo',
    'onboarding_sub_1': 'Find your match by answering questions',
    'onboarding_title_2': 'Create Your Questions',
    'onboarding_sub_2': 'Prepare 2-6 questions for people who want to match with you',
    'onboarding_title_3': 'Complete Your Profile',
    'onboarding_sub_3': 'Add photos and details to stand out',
    'next': 'Next',
    'skip': 'Skip',
    'get_started': 'Get Started',

    // Discover
    'discover': 'Discover',
    'no_more_profiles': 'No more profiles',
    'refresh': 'Refresh',
    'questions_count': '{count} questions',

    // Quiz
    'quiz_match': 'Match!',
    'quiz_match_desc': 'You answered all questions correctly!',
    'quiz_failed': 'Failed',
    'quiz_failed_desc': 'Wrong answer. Better luck next time!',

    // Matches
    'matches': 'Matches',
    'no_matches': 'No matches yet',
    'start_swiping': 'Start swiping to find matches!',

    // Chat
    'chat': 'Chat',
    'say_hello': 'Say hello!',
    'message_hint': 'Message...',
    'type_message': 'Type a message...',

    // Matches extras
    'new_matches': 'New Matches',
    'solve_to_meet': 'Solve Questions',
    'online': 'Online',
    'offline': 'Offline',

    // Profile
    'profile': 'Profile',
    'edit_profile': 'Edit Profile',
    'my_questions': 'My Questions',
    'diamonds': 'Diamonds',
    'passport': 'Passport',
    'complete': 'complete',

    // Questions
    'add_question': 'New Question',
    'question': 'Question',
    'answer_n': 'Answer {n}',
    'correct_answer': 'Correct Answer',
    'min_questions': 'Add at least {count} questions',
    'max_questions': 'Max 6 questions',

    // Diamonds
    'green_diamonds': 'Green Diamonds',
    'purple_diamonds': 'Purple Diamonds',
    'purchase_purple': 'Purple Diamond Packages',
    'history': 'Transaction History',
    'no_transactions': 'No transactions yet',
    'see_all': 'See All',
    'best_value': 'Best Value',
    'premium_cta': 'Upgrade to Qulo Premium!',
    'premium_benefits': 'Unlimited swipes, undos and monthly purple diamond bonus',
    'view_plans': 'View Plans',
    'active_plan': 'Active Plan',
    'expires_at': 'Expires: {date}',
    'your_balance': 'Your Balance',
    'failed_load_balance': 'Failed to load balance',

    // Passport
    'passport_explore': 'Explore profiles in another city',
    'passport_cost': 'Cost: {cost} purple diamonds / activation',
    'passport_active': 'Active: {city}',
    'city': 'City',
    'activate_passport': 'Activate Passport',
    'deactivate': 'Deactivate',
    'passport_premium_only': 'Passport mode is exclusive to Premium members',
    'passport_premium_desc': 'Upgrade to Premium to discover matches from any city',
    'passport_pick_on_map': 'Pick Location on Map',
    'passport_select_location': 'Drag the map to select a location',
    'passport_move_here': 'Move Here',
    'passport_active_desc': 'Discovery is based on this location',
    'passport_deactivate': 'Return to My Location',
    'passport_change_city': 'Move to a different city',
    'passport_explore_hint': 'Explore other cities with Passport',
    'passport_premium_explore_hint': 'Explore other cities with Premium',
    'upgrade_to_premium': 'Upgrade to Premium',

    // Discover Empty State
    'no_more_profiles_hint': 'Increase your distance range to see more people',
    'match_radius': 'Match Distance',
    'search_again': 'Search Again',

    // Location
    'location_required': 'Location permission required',
    'location_required_desc': 'Enable location to see people nearby',

    // Settings
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'delete_account': 'Delete Account',
    'delete_account_desc': 'This action is irreversible. All your data will be deleted.',

    // Powers
    'power_copy': 'Copy',
    'power_half': '50/50',
    'power_skip': 'Skip',
    'power_hint': 'Hint',
    'power_time': '+15s',
    'power_skip_all': 'Skip All',

    // Error codes
    'error_invalid_credentials': 'Email or password is incorrect',
    'error_email_already_exists': 'This email is already registered',
    'error_email_not_verified': 'Please verify your email first',
    'error_validation_error': 'Please check your input',
    'error_rate_limited': 'Too many attempts, please try again later',
    'error_server_error': 'Something went wrong, please try again',
    'error_unknown': 'An unexpected error occurred',

    // Register wizard
    'step_name': "What's your name?",
    'step_birthday': "When's your birthday?",
    'step_gender': 'How do you identify?',
    'step_email': 'Create your account',
    'step_terms': 'Almost there!',
    'birthday': 'Date of birth',
    'select_date': 'Select date',
    'must_be_18': 'You must be at least 18 years old',
    'man': 'Man',
    'woman': 'Woman',
    'other': 'Other',
    'continue_btn': 'Continue',
    'accept_terms': 'I accept the',
    'terms_of_service': 'Terms of Service',
    'privacy_policy': 'Privacy Policy',
    'and_word': 'and',
    'must_accept_terms': 'You must accept the terms to continue',

    // Location step
    'step_location': 'Share your location',
    'step_location_desc':
        'We need your location to match you with people nearby.',
    'enable_location': 'Enable Location',
    'location_granted': 'Location acquired',
    'location_skip': 'Skip for now',
    'location_service_disabled': 'Location services are off. Please enable in settings.',
    'location_permission_denied': 'Location permission denied.',
    'location_permission_denied_forever':
        'Location permission permanently denied. Enable in settings.',
    'open_settings': 'Open Settings',

    // Profile - Badge
    'badge_rookie': 'Rookie',
    'badge_popular': 'Popular',
    'badge_master': 'Profile Master',
    'badge_no_badge': 'Beginner',
    'badge_progress_hint': 'left',
    'badge_reward_claimed': 'Congratulations! You earned purple diamonds!',
    'badge_claim_reward': 'Claim Reward',
    'badge_discover_warning': 'Complete your profile to appear in discover!',

    // Profile - Hints
    'hint_add_photos': 'Add 3 photos → 20% more visibility!',
    'hint_add_bio': 'Add a bio → more matches!',
    'hint_add_job': 'Add your job → complete your profile!',
    'hint_add_details': 'Add details → level up your profile!',

    // Profile - Edit
    'edit_photos': 'Photos',
    'edit_about': 'About Me',
    'edit_basic_info': 'Basic Info',
    'edit_details': 'Details',
    'edit_preferences': 'Preferences',
    'save_changes': 'Save Changes',
    'bio_hint': 'Tell a bit about yourself...',
    'city_hint': 'Which city do you live in?',
    'job_hint': 'What do you do?',
    'school_hint': 'Where did you study?',
    'pets_hint': 'Do you have any pets?',
    'music_hint': 'Favorite music genre?',
    'personality_hint': 'How would you describe yourself?',
    'update_location': 'Update Location',
    'make_primary': 'Make Primary Photo',
    'delete_photo': 'Delete Photo',
    'delete_photo_confirm': 'Are you sure you want to delete this photo?',
    'photo_upload_error': 'Failed to upload photo',
    'photo_max_reached': 'Maximum 6 photos allowed',
    'changes_saved': 'Changes saved',
    'select_photo_source': 'Photo Source',
    'from_gallery': 'Choose from Gallery',
    'from_camera': 'Camera',

    // Details labels
    'height': 'Height',
    'weight': 'Weight',
    'zodiac': 'Zodiac',
    'job': 'Job',
    'school': 'School',
    'smoking': 'Smoking',
    'alcohol': 'Alcohol',
    'pets_label': 'Pets',
    'music_type': 'Music Type',
    'personality': 'Personality',
    'cm': 'cm',
    'kg': 'kg',

    // Preferences
    'gender_preference': 'Gender Preference',
    'distance_range': 'Distance',
    'km': 'km',
    'men': 'Men',
    'women': 'Women',
    'both': 'Everyone',

    // Zodiac signs
    'zodiac_aries': 'Aries',
    'zodiac_taurus': 'Taurus',
    'zodiac_gemini': 'Gemini',
    'zodiac_cancer': 'Cancer',
    'zodiac_leo': 'Leo',
    'zodiac_virgo': 'Virgo',
    'zodiac_libra': 'Libra',
    'zodiac_scorpio': 'Scorpio',
    'zodiac_sagittarius': 'Sagittarius',
    'zodiac_capricorn': 'Capricorn',
    'zodiac_aquarius': 'Aquarius',
    'zodiac_pisces': 'Pisces',

    // Subscription
    'sub_choose_plan': 'Choose Your Plan',
    'sub_plan_free': 'Free',
    'sub_plan_plus': 'Qulo Plus',
    'sub_plan_premium': 'Qulo Premium',
    'sub_price_free': 'Free',
    'sub_price_plus': '\$4.99/mo',
    'sub_price_premium': '\$9.99/mo',
    'sub_recommended': 'RECOMMENDED',
    'sub_current_plan': 'Current Plan',
    'sub_restore_purchases': 'Restore Purchases',
    'sub_purchase_coming_soon': 'Purchase coming soon',
    'sub_restore_done': 'Purchases restored',
    'sub_free_discovers': '50 discovers/day',
    'sub_free_questions': '4 question slots',
    'sub_free_ads': 'Contains ads',
    'sub_plus_discovers': 'Unlimited discovers',
    'sub_plus_questions': '6 question slots',
    'sub_plus_diamonds': '500 purple diamonds/mo',
    'sub_plus_undos': '3 undos/day',
    'sub_plus_no_ads': 'No ads',
    'sub_premium_discovers': 'Unlimited discovers',
    'sub_premium_questions': '10 question slots',
    'sub_premium_diamonds': '1500 purple diamonds/mo',
    'sub_premium_undos': 'Unlimited undos',
    'sub_premium_passport': 'Passport mode',
    'sub_premium_no_ads': 'No ads',

    'purchase_success': 'Purchase successful!',
    'purchase_failed': 'Purchase failed',

    // Upsell
    'diamonds_empty': 'Out of diamonds!',
    'swipe_limit_reached': 'Daily swipe limit reached',
    'first_match_congrats': 'Congrats on your first match!',
    'want_more_matches': 'Want more matches?',
    'special_offer': 'Special Offer',
    'limited_time': 'Limited time',
    'upgrade_now': 'Upgrade Now',
    'get_diamonds': 'Get Diamonds',
    'maybe_later': 'Maybe later',
    'unlock_unlimited': 'Unlock unlimited access',

    // Frequency
    'freq_yes': 'Yes',
    'freq_no': 'No',
    'freq_sometimes': 'Sometimes',

    // Discover & Matches (i18n cleanup)
    'solve_questions': 'Solve Questions',
    'unknown_user': 'Unknown',

    // Question Gate & Nudge
    'question_nudge_title': 'Add questions to be discovered!',
    'question_nudge_subtitle': 'Your profile is %{percent} ready — just questions missing!',
    'question_nudge_progress': '{count}/2 questions',
    'question_nudge_add_button': 'Add My Questions',
    'question_nudge_edit_hint': 'Great job editing your profile! Don\'t forget to add at least 2 questions to appear in matches.',
    'question_nudge_go_questions': 'Go to My Questions',
    'question_nudge_discover_locked': 'Add your questions to start discovering!',
    'question_nudge_celebration_title': 'Congratulations! You\'re now discoverable!',
    'question_nudge_celebration_button': 'Start Discovering',
    'question_nudge_menu_required': '2 questions required',

    // Notifications
    'notifications': 'Notifications',
    'mark_all_read': 'Mark All Read',
    'no_notifications': 'No notifications yet',
    'just_now': 'Just now',
    'minutes_ago': '{} min ago',
    'hours_ago': '{} hours ago',
    'days_ago': '{} days ago',

    // Version & Update
    'update_required_title': 'Update Required',
    'update_required_message': 'Please update the app to continue using it.',
    'update_available_title': 'Update Available',
    'update_available_message': 'Update the app for a better experience.',
    'update_button': 'Update',
    'update_later': 'Later',
    'maintenance_title': 'Under Maintenance',
    'maintenance_default_message': 'The app is currently under maintenance. Please try again later.',

    // Question Creation
    'question_create_title': 'Create Question',
    'question_edit_title': 'Edit Question',
    'question_create_easy_mode': 'Easy Mode',
    'question_create_advanced_mode': 'Advanced Mode',
    'question_create_step_question': 'Write Question',
    'question_create_step_answers': 'Add Answers',
    'question_create_step_settings': 'Settings',
    'question_create_motto': 'Ask questions about yourself — not Googleable!',
    'question_create_motto_tip': 'Tip: Personal questions like "My favorite season?" get more solves',
    'question_create_select_category': 'Select Category',
    'question_create_select_time': 'Select Time',
    'question_create_hint_label': 'Hint (optional)',
    'question_create_preview': 'Preview',
    'question_create_save': 'Save',
    'question_create_update': 'Update',

    // Categories
    'question_category_personality': 'Personality',
    'question_category_music': 'Music',
    'question_category_film': 'Film',
    'question_category_sports': 'Sports',
    'question_category_travel': 'Travel',
    'question_category_food': 'Food',
    'question_category_technology': 'Technology',
    'question_category_general': 'General',
    'question_category_other': 'Other',

    // Time Presets
    'question_time_fast': 'Fast',
    'question_time_fast_desc': 'Don\'t think, feel!',
    'question_time_normal': 'Normal',
    'question_time_normal_desc': 'Standard pace',
    'question_time_relaxed': 'Relaxed',
    'question_time_relaxed_desc': 'Time to think',
    'question_time_thoughtful': 'Thoughtful',
    'question_time_thoughtful_desc': 'Hard questions deserve it',

    // AI Suggestions
    'ai_suggest_title': 'AI Question Suggestions',
    'ai_suggest_category': 'Suggest by category',
    'ai_suggest_profile': 'Suggest based on my profile',
    'ai_suggest_loading': 'Preparing questions...',
    'ai_suggest_select': 'Select This Question',
    'ai_suggest_empty': 'No suggestions found, try again',

    // Analytics
    'analytics_title': 'Question Stats',
    'analytics_total_solves': 'Total Solves',
    'analytics_success_rate': 'Success Rate',
    'analytics_green_earned': 'Green Diamonds Earned',
    'analytics_best_question': 'Best Question',
    'analytics_difficulty_easy': 'Easy',
    'analytics_difficulty_medium': 'Medium',
    'analytics_difficulty_hard': 'Hard',
    'analytics_difficulty_legendary': 'Legendary',
    'analytics_difficulty_unranked': 'Unranked',
    'analytics_avg_time': 'Avg. Time',
    'analytics_power_usage': 'Power Usage',
    'analytics_answer_distribution': 'Answer Distribution',
    'analytics_min_solves': 'At least 10 solves required for badge',
    'analytics_correct': 'Correct',
    'analytics_wrong': 'Wrong',
    'analytics_question_num': 'Question #{n}',
    'analytics_green_question': 'This question earned you {n} green diamonds',
    'analytics_no_data': 'No stats yet',
    'analytics_seconds': '{n}s',
    'analytics_answer_n': 'Answer {n}',

    // Pending Changes
    'pending_changes_title': 'Pending Changes',
    'pending_change_update': 'Edit pending',
    'pending_change_delete': 'Delete pending',
    'pending_change_cancel': 'Cancel',
    'pending_change_applied': 'Change applied',
    'pending_change_info': 'Change queued due to active quiz',

    // Quiz Result
    'quiz_result_flawless': 'Flawless',
    'quiz_result_speed_solver': 'Speed Solver',
    'quiz_result_power_master': 'Power Master',
    'quiz_result_determined': 'Determined',
    'quiz_result_time_spent': 'Time Spent',
    'quiz_result_powers_used': 'Powers Used',
    'quiz_result_matched': 'You Matched!',
    'quiz_result_not_matched': 'Not this time',
    'quiz_result_correct_count': '{correct}/{total} correct',
    'quiz_result_start_chat': 'Start Chat',
    'quiz_result_go_back': 'Go Back',

    // Chat Quiz Summary
    'chat_quiz_summary': 'Quiz Summary',
    'chat_quiz_summary_solved': 'Solved {count} questions in {time}s',

    // Discover Card
    'discover_questions_count': '{count} questions',
    'discover_difficulty': 'Difficulty',

    // Weekly Report
    'weekly_report_title': 'Weekly Report',
    'weekly_report_solves': 'Your questions were solved {count} times this week',
    'weekly_report_green': 'You earned {count} green diamonds',

    // Onboarding - Questions
    'onboarding_questions_slide1_title': 'Create Questions, Match!',
    'onboarding_questions_slide1_desc': 'Prepare your questions to match on Qulo. If someone answers all correctly, you match!',
    'onboarding_questions_slide2_title': 'Questions About You',
    'onboarding_questions_slide2_desc': 'Ask personal questions that can\'t be Googled. Questions like "My favorite meal?" are more fun!',
    'onboarding_questions_slide3_title': 'Earn Green Diamonds!',
    'onboarding_questions_slide3_desc': 'When someone uses a power on your questions, you earn 30% of their purple diamond spend as green diamonds!',
    'onboarding_questions_start': 'Get Started',
    'onboarding_questions_later': 'Later',

    // Profile Vitrin
    'profile_vitrin_solves': 'times solved',
    'profile_vitrin_success': 'success rate',
    'profile_vitrin_green': 'earned',
    'profile_vitrin_title': 'Your Question Stats',

    // Mode Selection
    'question_mode_title': 'How would you like to create?',
    'question_mode_easy_desc': 'AI suggests questions, you pick',
    'question_mode_advanced_desc': 'Create step by step yourself',

    // Progressive Nudge
    'nudge_easy_mode_hint': 'Create a question in 30 seconds with Easy Mode!',
    'nudge_easy_mode_button': 'Start with Easy Mode',
    'nudge_quick_create_title': 'Quick Question Create',
    'nudge_profile_suggest': 'Suggest based on my profile',

    // Subscription celebration
    'celebration_title_plus': 'Welcome to Qulo Plus!',
    'celebration_title_premium': 'Welcome to Qulo Premium!',
    'celebration_diamonds_plus': '+500 Purple Diamonds',
    'celebration_diamonds_premium': '+1500 Purple Diamonds',
    'celebration_diamonds_desc': 'Your monthly bonus has been added',
    'celebration_button': 'Awesome!',

    // Subscription profile
    'sub_my_subscription': 'My Subscription',
    'sub_free_upgrade': 'Free Plan • Upgrade',

    // Monthly benefits
    'monthly_benefits_title': 'My Benefits',
    'benefit_daily_discovers': 'Daily Discovers',
    'benefit_daily_undos': 'Daily Undos',
    'benefit_question_slots': 'Question Slots',
    'benefit_monthly_diamonds': 'Monthly Diamonds',
    'benefit_passport': 'Passport Mode',
    'benefit_ads': 'Ads',
    'benefit_unlimited': 'Unlimited',
    'benefit_given': 'Given',
    'benefit_active': 'Active',
    'benefit_inactive': 'Inactive',
    'benefit_none': 'None',
    'benefit_no_ads': 'No Ads',
    'benefit_has_ads': 'Has Ads',

    // Language system
    'question_language': 'Question language',
    'language_picker_title': 'Which languages can you answer questions in?',
    'language_picker_select_one': 'Select question language',
    'language_picker_hint': 'At least one language must be selected',
    'settings_question_languages': 'Question Languages',
    'settings_question_languages_none': 'No languages selected yet',
    'onboarding_questions_slide4_title': 'Which Languages Do You Know?',
    'onboarding_questions_slide4_desc': 'We\'ll show you profiles with questions in your languages. You can select multiple!',
    // Locale names (native names, same in both languages)
    'locale_tr': 'T\u00fcrk\u00e7e',
    'locale_en': 'English',
    'locale_de': 'Deutsch',
    'locale_fr': 'Fran\u00e7ais',
    'locale_es': 'Espa\u00f1ol',
    'locale_ar': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    'locale_ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    'locale_pt': 'Portugu\u00eas',
    'locale_it': 'Italiano',
    'locale_ja': '\u65e5\u672c\u8a9e',
    'locale_ko': '\ud55c\uad6d\uc5b4',
    'locale_zh': '\u4e2d\u6587',
    'locale_nl': 'Nederlands',
    'locale_pl': 'Polski',
    'locale_sv': 'Svenska',
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
