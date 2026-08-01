# Qulo 2.0.7 (build 68) — Release Notes / What's New

**Faz 2 — Eşleşme Motoru.** Bu sürümün tek konusu var: quiz'i geçilebilir kılmak.

Prod ölçümü sorunu şöyle gösterdi: 83 quiz oturumunun sadece 8'i tamamlandı (%9.6),
güç kullanımı **0 oturum**, kasada 2000+ atıl mor elmas. Sebep koddan doğrulandı —
güç butonları envantere bağlıydı, envanteri dolduran tek yol satın almaktı, hiçbir
yerde başlangıç gücü verilmiyordu. Yani herkes 6 gri ikonla başlıyordu.

## Kullanıcıya görünen değişiklikler
- **Güçler elmasla doğrudan kullanılabiliyor** (quiz + sohbet soruları). Önce satın
  alma zorunluluğu kalktı; envanterde hak varsa oradan, yoksa mor elmastan düşüyor.
- **Yeni üyelere 2 Kâhin gücü** hediye (envanter — mor elmas ekonomisi değişmiyor).
- **Fiyat butonun altında.** Ayrıca 2 soruluk quizde fiyat 2 kat fazla gösteriliyordu,
  düzeldi (çarpan artık sunucuda tek yerden hesaplanıyor).
- **"Hepsini Geç" sadece avantajlıysa çıkıyor.** 2 soruluk quizde iki ayrı "Doğru Say"
  20 elmas iken "Hepsini Geç" 30 elmastı — aynı sonuç, %50 daha pahalı.
- **Soru oluşturma:** aynı şıklar uyarılıyor (hem uygulamada hem sunucuda), zorluk
  rehberliği eklendi. "Google'da bulunmasın" tonu 16 dilde dengeli metne çevrildi —
  cevap doğruluk oranı %35 idi, sorular fazla zordu.

## Kullanıcıya görünmeyen ama önemli
- Güç kullanımında **çift ücretlendirme koruması** (server otorite, atomik RPC).
- Terk edilmiş sohbet sorusuna güç kullanılıp elmas yakılması engellendi.
- Bakiye göstergeleri güç kullanımından sonra doğru tazeleniyor.
- Güç hunisi artık ölçülüyor (`quiz_power_*`, `chat_power_*`, `*_rescue_*`).

Migration: **036** (`quiz_sessions.current_q_powers`) ve **037** (atomik işaretleme RPC'leri).

---

## 📱 APP STORE — "What's New"

Kaynak: `scripts/testflight_release_notes.json` (16 dil, tek kaynak).
Push: `APP_STORE_API_KEY=... APP_STORE_API_ISSUER=... node scripts/push_appstore_whatsnew.mjs`

> Not: `scripts/asc_whatsnew.mjs` eski bir kopya — kendi içinde **hardcoded 2.0.5**
> metni ve sürüm numarası taşıyor. Onu çalıştırma, güncel olan `push_appstore_whatsnew.mjs`.

### tr
• Güçler artık doğrudan elmasla kullanılabiliyor — önceden satın almana gerek yok
• Yeni üyelere hoş geldin hediyesi: 2 Kâhin gücü
• Fiyat butonun altında — harcamadan önce ne kadar elmas gideceğini görüyorsun
• Soru oluşturma iyileştirildi: aynı şıklar uyarılıyor, soruların tahmin edilebilir kalması için ipucu veriliyor
• Çeşitli hata düzeltmeleri ve performans iyileştirmeleri

### en-US
• Powers now work straight from your diamonds — no need to buy them first
• Welcome gift for new members: 2 Oracle powers
• The price is right on the button — see what you'll spend before you spend it
• Better question creation: we flag duplicate options and help keep your questions guessable
• Various bug fixes and performance improvements

### de-DE
• Kräfte funktionieren jetzt direkt mit deinen Diamanten — kein vorheriger Kauf nötig
• Willkommensgeschenk für neue Mitglieder: 2 Orakel-Kräfte
• Der Preis steht direkt auf dem Button — du siehst vorher, was es kostet
• Bessere Fragenerstellung: doppelte Antworten werden erkannt, und wir helfen dir, Fragen erratbar zu halten
• Diverse Fehlerbehebungen und Leistungsverbesserungen

### fr-FR
• Les pouvoirs s'utilisent désormais directement avec tes diamants — plus besoin de les acheter d'abord
• Cadeau de bienvenue pour les nouveaux membres : 2 pouvoirs Oracle
• Le prix est affiché sur le bouton — tu vois ce que ça coûte avant de dépenser
• Création de questions améliorée : on repère les réponses identiques et on t'aide à garder tes questions devinables
• Corrections de bugs et améliorations des performances

### es-ES
• Los poderes ahora se usan directamente con tus diamantes — no hace falta comprarlos antes
• Regalo de bienvenida para nuevos miembros: 2 poderes Oráculo
• El precio está en el botón — ves lo que gastarás antes de gastarlo
• Creación de preguntas mejorada: avisamos si repites opciones y te ayudamos a que sean adivinables
• Varias correcciones de errores y mejoras de rendimiento

### ar-SA
• أصبح بإمكانك استخدام القوى مباشرة بالألماس — دون شرائها مسبقًا
• هدية ترحيب للأعضاء الجدد: قوتا العرّاف
• السعر ظاهر على الزر — ترى التكلفة قبل الإنفاق
• تحسين إنشاء الأسئلة: ننبّهك للخيارات المكرّرة ونساعدك على إبقاء الأسئلة قابلة للتخمين
• إصلاحات متنوعة للأخطاء وتحسينات في الأداء

### ru
• Способности теперь работают прямо с ваших алмазов — покупать заранее не нужно
• Приветственный подарок новым участникам: 2 способности «Оракул»
• Цена прямо на кнопке — вы видите расход до того, как потратите
• Улучшено создание вопросов: предупреждаем о повторяющихся вариантах и помогаем сохранить их угадываемыми
• Различные исправления ошибок и улучшения производительности

### pt-PT
• Os poderes agora funcionam direto com os seus diamantes — sem precisar comprar antes
• Presente de boas-vindas para novos membros: 2 poderes Oráculo
• O preço está no botão — você vê quanto vai gastar antes de gastar
• Criação de perguntas melhorada: avisamos sobre opções repetidas e ajudamos a mantê-las adivinháveis
• Várias correções de erros e melhorias de desempenho

### it
• I poteri ora funzionano direttamente con i tuoi diamanti — non serve comprarli prima
• Regalo di benvenuto per i nuovi membri: 2 poteri Oracolo
• Il prezzo è sul pulsante — vedi quanto spendi prima di spendere
• Creazione domande migliorata: segnaliamo le risposte doppie e ti aiutiamo a renderle indovinabili
• Varie correzioni di bug e miglioramenti delle prestazioni

### ja
• パワーがダイヤモンドで直接使えるようになりました — 事前購入は不要です
• 新規メンバーへのウェルカムギフト：オラクル2つ
• 価格はボタンに表示 — 使う前にコストがわかります
• 質問作成が改善：重複した選択肢をお知らせし、推測できる質問づくりをお手伝いします
• 各種バグ修正とパフォーマンス改善

### ko
• 이제 파워를 다이아몬드로 바로 사용할 수 있어요 — 미리 구매할 필요 없습니다
• 신규 회원 환영 선물: 오라클 2개
• 가격이 버튼에 표시돼요 — 쓰기 전에 비용을 확인할 수 있습니다
• 질문 만들기 개선: 중복된 보기를 알려드리고, 맞힐 수 있는 질문을 만들도록 도와드려요
• 다양한 버그 수정 및 성능 개선

### zh-Hans
• 现在可以直接用钻石使用能力 — 无需提前购买
• 新会员欢迎礼：2 个神谕
• 价格就在按钮上 — 花之前就能看到消耗
• 出题体验优化：重复选项会有提示，帮你把问题保持在能猜到的范围
• 多项错误修复与性能优化

### nl-NL
• Krachten werken nu direct met je diamanten — je hoeft ze niet vooraf te kopen
• Welkomstcadeau voor nieuwe leden: 2 Orakel-krachten
• De prijs staat op de knop — je ziet vooraf wat het kost
• Betere vragen maken: we waarschuwen bij dubbele antwoorden en helpen je vragen raadbaar te houden
• Diverse bugfixes en prestatieverbeteringen

### pl
• Moce działają teraz bezpośrednio z Twoich diamentów — nie musisz ich wcześniej kupować
• Prezent powitalny dla nowych członków: 2 moce Wyroczni
• Cena jest na przycisku — widzisz koszt, zanim wydasz
• Lepsze tworzenie pytań: ostrzegamy o powtórzonych odpowiedziach i pomagamy zachować je odgadywalnymi
• Różne poprawki błędów i ulepszenia wydajności

### sv
• Krafter fungerar nu direkt med dina diamanter — du behöver inte köpa dem först
• Välkomstgåva till nya medlemmar: 2 Orakel-krafter
• Priset står på knappen — du ser kostnaden innan du spenderar
• Bättre frågeskapande: vi flaggar dubbla svarsalternativ och hjälper dig hålla frågorna gissningsbara
• Diverse buggfixar och prestandaförbättringar

### hi
• अब पावर सीधे आपके डायमंड से चलती हैं — पहले खरीदने की ज़रूरत नहीं
• नए सदस्यों के लिए वेलकम गिफ्ट: 2 ओरेकल पावर
• कीमत बटन पर ही दिखती है — खर्च करने से पहले लागत देखें
• सवाल बनाना बेहतर हुआ: एक जैसे विकल्पों पर चेतावनी और सवाल अंदाज़ा लगाने लायक रखने में मदद
• कई बग फिक्स और परफ़ॉर्मेंस सुधार

---

## 🧪 TESTFLIGHT — "What to Test"

Aynı metinler (`scripts/testflight_release_notes.json`). Beta testçilerine ek olarak
şunları söyle:

1. **Envanterin 0 iken bir güce bas** (elmas bakiyen olsun) — elmas düşüyor mu, üstteki
   bakiye anında güncelleniyor mu? *Bu sunucu yolu bugüne kadar hiç çalışmamıştı.*
2. **Aynı güce iki kez bas** — ikincide ücret alınmamalı, buton tikli olmalı.
   TIME_EXTEND dahil, hem quizde hem sohbet sorusunda.
3. **2 soruluk quizde** rescue ekranında "Doğru Say" 10 elmas yazmalı ve 10 düşmeli;
   "Hepsini Geç" hiç görünmemeli.
4. **Yeni hesap aç** — Kâhin butonunda "2" rozeti çıkmalı.
5. **Soru oluştururken aynı iki şıkkı yaz** — kırmızı hata + "İleri" kapalı olmalı,
   yazarken önizleme canlı güncellenmeli.
