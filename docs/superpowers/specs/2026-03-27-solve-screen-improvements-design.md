# Soru Çözme Ekranı İyileştirmeleri

**Tarih:** 2026-03-27
**Kapsam:** SolveChatQuestionScreen ve ilgili widget'lar

## 1. Sorunun Tekrar Çözülebilmesi (Bug Fix)

### Problem
Kullanıcı soruyu cevapladıktan sonra geri çıkıp tekrar soruya tıklayınca soru çözme ekranı yeniden açılabiliyor. Server tarafında `ALREADY_ANSWERED` guard var ama client tarafında eksik.

### Çözüm

**Client-side guard (SolveChatQuestionScreen):**
- `initMixin()` içinde `widget.question.isAnswered` kontrolü ekle
- `true` ise `WidgetsBinding.instance.addPostFrameCallback` ile ekranı kapat (pop)
- Bu, cache'den eski veri gelse bile koruma sağlar

**Cache refresh düzeltmesi (ChatQuestionMessage):**
- `_openSolveScreen` dönüşünde mevcut refresh mantığı çalışıyor ama gecikme var
- Çözme ekranından `Navigator.pop(context, true)` ile "cevaplandı" bilgisi dön
- `_openSolveScreen`'de pop sonucunu kontrol et, `true` ise cache'i hemen güncelle
- `chatQuestionCacheProvider` içindeki modelin `answeredOption`'ını set et → kart anında "cevaplanmış" state'e geçer

### Etkilenen Dosyalar
- `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — isAnswered guard
- `lib/features/chat/screens/solve_chat_question_screen.dart` — pop ile sonuç dönme
- `lib/features/chat/widgets/chat_question_message.dart` — pop sonucunu handle etme

---

## 2. Güç Envanteri Gösterimi

### Gereksinim
Her güç butonunda kullanıcının kaç adet o güce sahip olduğu görünmeli.

### Tasarım

**Power button badge:**
- Her `_ChatPowerButton`'ın sağ üst köşesinde küçük yuvarlak badge
- Badge içinde envanter sayısı (ör. "3")
- Envanter 0 ise badge gösterilmez, buton %40 opacity ile gösterilir
- Badge rengi: güç butonunun kendi rengi

**Veri akışı:**
- `SolveQuestionBody`'ye `exchangeState` parametresi ekle (veya doğrudan ConsumerWidget yap)
- `ChatQuestionPowerBar`'a `Map<String, int> powerCounts` parametresi ekle
- `exchangeProvider` watch edilerek canlı envanter sayıları alınır
- `exchangeProvider` henüz fetch edilmemişse `initMixin()` içinde `ref.read(exchangeProvider.notifier).fetchAll()` çağır

### Etkilenen Dosyalar
- `lib/features/chat/widgets/chat_question_power_bar.dart` — badge ekleme
- `lib/features/chat/widgets/solve_question_body.dart` — powerCounts parametresi
- `lib/features/chat/screens/solve_chat_question_screen.dart` — exchangeProvider watch
- `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — fetchAll çağrısı

---

## 3. Elmas Bakiyesi Gösterimi

### Gereksinim
Soru çözerken kullanıcının mor ve yeşil elmas bakiyesi görünmeli.

### Tasarım

**Konum:** AppBar'ın `actions` alanına kompakt elmas widget'ı ekle.

**Widget yapısı:**
```
[💜 150  💚 45]
```
- `DiamondIcon.purple(size: 16, showGlow: false)` + sayı
- `DiamondIcon.green(size: 16, showGlow: false)` + sayı
- Küçük font (12px), AppBar'a sığacak kadar kompakt
- `diamondProvider` watch edilerek canlı güncellenir
- Güç kullanımı sonrası `ref.invalidate(diamondProvider)` zaten mevcut

**Yeni widget:** `_CompactDiamondBalance` — sadece bu ekrana özel, ayrı dosyaya gerek yok, `solve_chat_question_screen.dart` içinde tanımlanır.

### Etkilenen Dosyalar
- `lib/features/chat/screens/solve_chat_question_screen.dart` — AppBar actions

---

## 4. Karşı Kişinin Profil Fotoğrafı

### Gereksinim
Soru çözerken karşı kişinin profil fotoğrafını görmek motivasyon sağlar.

### Tasarım

**Veri geçişi:**
- `SolveChatQuestionScreen`'e `matchId` parametresi ekle
- Route tanımında `extra` olarak `{'question': question, 'matchId': matchId}` geç
- Ekran içinde `matchListProvider` watch ederek match user bilgisi al

**UI konumu:** Soru metninin üstünde, ortada:
```
    [CircleAvatar 40px]
    "Ayşe'nin sorusu"
```
- `CircleAvatar` + `CachedNetworkImage` ile fotoğraf
- Fotoğraf yoksa varsayılan ikon
- Altında kullanıcının adı + "... sorusu" metni
- Font: 12px, secondary renk

**Konum:** `SolveQuestionBody`'nin en üstüne, timer'dan önce yerleştirilir.

### Etkilenen Dosyalar
- `lib/features/chat/screens/solve_chat_question_screen.dart` — matchId parametresi
- `lib/features/chat/widgets/solve_question_body.dart` — profil fotoğrafı widget
- `lib/features/chat/widgets/chat_question_message.dart` — navigation'a matchId ekleme
- `lib/routing/app_routes.dart` — route extra güncelleme

---

## Kapsam Dışı
- Güç satın alma UI'ı (zaten exchange ekranında mevcut)
- Animasyonlar, confetti efektleri
- Cevap sonrası sosyal paylaşım
