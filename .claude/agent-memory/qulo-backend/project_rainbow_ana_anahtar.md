---
name: project-rainbow-ana-anahtar
description: Rainbow + market ana anahtarı economy config `rainbow.enabled` (2026-09-30, d125d07); kapalıyken yalnız is_test_account; açmadan önce 133 hatalı is_test_admin temizlenmeli
metadata:
  type: project
---

Rainbow (3. elmas) + market için tek ana anahtar: etkin economy config'teki `rainbow.enabled` (yoksa/false → kapalı).
Kapalıyken erişim yalnız `is_test_account=true` ve seed olmayan hesaplar; `is_test_admin` tek başına açmaz.
Açıkken eski kurallar: test admin her yerde + `reward_market_countries` ülke/platform bayrakları. Commit d125d07 (2026-09-30).

**Why:** Kullanıcı 2026-09-30'da Rainbow'un 2.0.14'te gömülü kalmasına karar verdi. Prod'da test hesabı olmayan 133 kullanıcıda
`is_test_admin=true` (kayıt default drift'i; 073 yalnız DEFAULT'u düzeltti, mevcut satırlar true kaldı). `app_config` sütunlu tablo
(yeni anahtar = migration) ve o oturumda Supabase MCP yoktu → sürümlü, önbellekli, backoffice JSON editörlü economy config seçildi.

**How to apply:**
- Anahtarı açma = backoffice → Economy Config → JSON'da `"rainbow": {"enabled": true, ...}` + sebep → Kaydet (yeni sürüm). SQL ile yazma
  (önbellek tazelenmez; bozuk değer tüm economy config'i okunmaz yapar).
- **Açmadan önce** 133 hatalı `is_test_admin` temizlenmeli — açılınca hepsi tüm ülkeler + tavansız + taslak + `is_test` itfa alır
  (toplu UPDATE → kullanıcı onayı). Kart `tasks/board/2026-09-30-rainbow-ana-anahtar.md`.
- Yeni Rainbow giriş noktası eklenirse `rainbowAccessService.isEnabled/isEnabledForUser`'dan geçmeli; testlerde anahtar açık için
  `rainbowSwitchRow(true)` (fixture varsayılanı açık), kapalı için `rainbowSwitchRow(false)`.
- İlgili: [[reference-salt-okuma-prod-probe]]
