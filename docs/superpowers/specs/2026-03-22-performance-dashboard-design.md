# Performans Analizi Dashboard

**Tarih:** 2026-03-22
**Durum:** Onaylandi

## Ozet

Kullanicinin soru performansi, elmas ekonomisi ve genel istatistiklerini gosteren yeni bir dashboard ekrani + sorular ekranindaki bos analytics ikonunun duzeltilmesi.

## Erisim Noktalari

### A — Profil Menusu
- `ProfileMenuList`'e yeni "Performans Analizi" satiri eklenir
- Ikon: bar_chart veya analytics ikonu
- Tiklayinca `PerformanceDashboardScreen` acilir

### B — Sorular Ekrani (Bug Fix)
- Sag ust `icChart` ikonu su an `onPressed: () {}` (bos callback)
- Mevcut `QuestionAnalyticsScreen`'e navigate etmesi lazim
- Bu bir bug fix — yeni feature degil

## Dashboard Ekrani

### Bolum 1: Genel Ozet Kartlari

2x2 grid, 4 istatistik karti:

| Kart | Veri | Kaynak |
|------|------|--------|
| Toplam cozulme sayisi | Tum sorularimin toplam solve_count'u | `/questions/me/analytics` → totals.totalSolveCount |
| Genel basari orani | Tum sorularimin ortalama basari (int, 0-100 arasi) | `/questions/me/analytics` → totals.overallSuccessRate (int, `%$value` formatla) |
| Toplam kazanilan yesil elmas | Sorularimdan toplam yesil kazanci | `/questions/me/analytics` → totals.totalGreenEarned |
| Toplam harcanan mor elmas | Kullanicinin toplam mor harcamasi | `userProvider` baslangic mor - mevcut mor (yaklasik) veya backend `GET /api/v1/diamonds/stats` (v2) |

### Bolum 2: Elmas Ekonomisi

- **Bakiye gosterimi:** Yesil ve mor elmas bakiye (mevcut `userProvider` → user.greenDiamonds, user.purpleDiamonds)
- **Son islemler listesi:** Son 20 elmas islemi (mevcut `GET /api/v1/diamonds/history` endpoint'i)
- **Islem satiri:** Tarih, miktar (+/-), sebep etiketi (guc kullanimi, boost, IAP, referral vb.)
- **"Tumunu Gor" butonu:** Elmas sayfasina (`RouteNames.diamonds`) yonlendirir

### Bolum 3: Soru Performansi Ozeti

- **En iyi sorum:** En cok yesil elmas kazandiran soru (mevcut totals.bestQuestionOrder, nullable — null ise "Henuz veri yok" goster)
- **En zor sorum:** En dusuk basari oranli soru (questions listesinden hesaplanir, en az 1 solve gerekli — yoksa gosterme)
- **Ortalama cozum suresi:** Tum sorularin avg_time ortalamasi
- **Zorluk dagilimi:** Kac sorum kolay/orta/zor/efsane — chip veya mini bar seklinde
  - Zorluk degeri: backend'den hazir gelen `difficulty_badge` string'i (`easy`/`medium`/`hard`/`legendary`)
  - Client-side sadece gruplama yapar (questions.groupBy(difficultyBadge))
  - i18n eslestirme: `easy` → kolay, `medium` → orta, `hard` → zor, `legendary` → efsane, `unranked` → siralanmamis

## Teknik Yaklasim

### Yeni Dosyalar
- `lib/features/performance/screens/performance_dashboard_screen.dart` — ana ekran
- `lib/features/performance/mixins/performance_dashboard_mixin.dart` — ekran logic'i
- `lib/features/performance/widgets/performance_summary_grid.dart` — 2x2 ozet kartlari
- `lib/features/performance/widgets/diamond_economy_section.dart` — elmas ekonomisi bolumu
- `lib/features/performance/widgets/question_performance_section.dart` — soru performansi bolumu
- `lib/features/performance/widgets/diamond_transaction_tile.dart` — tek islem satiri widget'i

### Veri Kaynagi
Neredeyse tum veriler mevcut endpoint'lerden gelir:

1. **Soru analitikleri:** `GET /api/v1/questions/me/analytics` (mevcut, calisan)
   - totals: totalSolveCount, overallSuccessRate, totalGreenEarned, bestQuestionOrder
   - questions[]: her sorunun stats'i (correct, wrong, avgTime, answerDistribution, powers)

2. **Elmas bakiye:** `userProvider` → user.greenDiamonds, user.purpleDiamonds (bellekte mevcut)

3. **Elmas gecmisi:** `GET /api/v1/diamonds/history?page=1&limit=20` (mevcut, calisan)

4. **Toplam mor harcama:** Mevcut diamond history'den client-side aggregation yapilabilir veya yeni basit endpoint eklenebilir

### Backend Degisikligi
- **Minimal:** Toplam mor harcama icin yeni endpoint gerekebilir (`GET /api/v1/diamonds/stats`)
- **Alternatif:** Client-side'da mevcut `diamond_transactions` history'sinden hesaplanabilir (ilk 100 islem yeterli MVP icin)
- **Karar:** MVP icin client-side aggregation, sonra backend endpoint

### Provider Mimarisi
- `performanceDashboardProvider` — tum verileri paralel cekenAsyncNotifier
  - `questionAnalyticsProvider` (mevcut) reuse edilir
  - `diamondHistoryProvider` (yeni veya mevcut) elmas gecmisi icin
  - `userProvider` (mevcut) bakiye icin

### Routing
- Route: `/profile/performance` (GoRouter, profile alt route'u)
- `RouteNames.performance` eklenir

### Mevcut Dosya Degisiklikleri
- `lib/features/profile/screens/questions_screen.dart:44` — `onPressed: () {}` → analytics navigasyonu (bug fix)
- `lib/features/profile/widgets/profile_menu_list.dart` — "Performans Analizi" menu satiri eklenir
- `lib/routing/route_names.dart` — `performance` eklenir
- `lib/routing/app_routes.dart` — `/profile/performance` route tanimlanir

### i18n Key'leri
- `performance_dashboard` — AppBar basligi
- `total_solves` — "Toplam Cozulme"
- `success_rate` — "Basari Orani"
- `green_earned` — "Kazanilan Yesil"
- `purple_spent` — "Harcanan Mor"
- `diamond_economy` — "Elmas Ekonomisi"
- `recent_transactions` — "Son Islemler"
- `view_all` — "Tumunu Gor"
- `question_performance` — "Soru Performansi"
- `best_question` — "En Iyi Sorum"
- `hardest_question` — "En Zor Sorum"
- `avg_solve_time` — "Ort. Cozum Suresi"
- `difficulty_distribution` — "Zorluk Dagilimi"
- `performance_analysis` — Menu satiri basligi

### Analytics Event'leri
- `performance_dashboard_opened` — dashboard acildi
- `performance_view_all_diamonds` — "Tumunu Gor" tiklandi
- `performance_best_question_tapped` — en iyi soru kartina tiklandi

### Empty State (Sifir Veri)
- **Hic sorusu olmayan kullanici:** "Henuz soru olusturmadiniz" mesaji + "Soru Olustur" butonu
- **Sorusu olan ama hic cozulmemis:** Ozet kartlari 0 deger gosterir, soru performansi "Henuz cozum yok" mesaji
- **Elmas gecmisi bos:** "Henuz islem yok" mesaji
- **bestQuestionOrder null:** "En Iyi Sorum" kartinda "Henuz veri yok" placeholder

### Loading/Error State
- `AppScaffold(isLoading: true)` → tum provider'lar yuklenirken
- Bolum bazli hata: bir bolum yuklenemezse diger bolumleri goster, hata olan bolumde retry butonu

### MVP Sinirlari
- Toplam mor harcama: MVP'de gosterilmez veya `userProvider`'dan yaklasik hesaplanir. Backend endpoint v2'de eklenir.
- Diamond history son 20 islem gosterilir, tam aggregation yok.
