# Terms of Service & Legal Compliance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ToS/Privacy Policy kabulünü server-side'da kayıt altına al, KVKK aydınlatma metni ekle, Settings'e Legal bölümü ekle — store submission için tam uyumlu hale getir.

**Architecture:** Mevcut register flow'a `tos_accepted` parametresi eklenir, server tarafında `user_consents` tablosuna kayıt düşülür. Web'deki mevcut ToS/PP sayfaları KVKK uyumlu güncellenir. Flutter Settings ekranına Legal bölümü eklenir. Tüm katmanlar (validator → service → provider → repository → UI) uçtan uca güncellenir.

**Tech Stack:** Node.js/Express/TypeScript (server), Flutter/Riverpod (mobile), Supabase PostgreSQL (DB), Next.js (web legal pages)

---

## File Structure

### Server (qulo-server)
- **Modify:** `src/validators/auth.validator.ts` — `tos_accepted` field ekle
- **Modify:** `src/services/auth.service.ts` — consent kaydı ekle + hardDeleteUser'a user_consents ekle
- **Create:** `src/services/consent.service.ts` — consent CRUD logic

### Flutter (qulov2)
- **Modify:** `lib/data/repositories/auth_repository.dart` — `tos_accepted` gönder
- **Modify:** `lib/providers/auth_provider.dart` — `tosAccepted` param ekle
- **Modify:** `lib/features/auth/mixins/register_screen_mixin.dart` — tosAccepted gönder
- **Create:** `lib/features/settings/widgets/settings_legal_section.dart` — Legal tile'lar
- **Modify:** `lib/features/settings/screens/settings_screen.dart` — Legal section ekle

### Web (web)
- **Modify:** `src/lib/i18n/dictionaries/tr.json` — KVKK bölümü ekle (termsOfService + privacyPolicy)
- **Modify:** `src/lib/i18n/dictionaries/en.json` — KVKK bölümü ekle

### Database
- **Migration:** `user_consents` tablosu oluştur

---

## Task 1: Database — user_consents Tablosu

**Files:**
- Create: Supabase SQL migration (via MCP tool)

- [ ] **Step 1: Migration SQL'i hazırla ve çalıştır**

```sql
-- user_consents: Tracks when users accepted which legal document version
CREATE TABLE IF NOT EXISTS user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL CHECK (consent_type IN ('terms_of_service', 'privacy_policy', 'kvkk_explicit')),
  version TEXT NOT NULL DEFAULT '1.0',
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address TEXT,
  app_version TEXT,
  platform TEXT CHECK (platform IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast lookups by user
CREATE INDEX idx_user_consents_user_id ON user_consents(user_id);

-- Unique constraint: one consent per type+version per user
CREATE UNIQUE INDEX idx_user_consents_unique ON user_consents(user_id, consent_type, version);
```

Supabase MCP `execute_sql` ile çalıştır.

- [ ] **Step 2: Tabloyu doğrula**

Supabase MCP `list_tables` ile `user_consents` tablosunun oluştuğunu doğrula.

- [ ] **Step 3: Commit**

```bash
# Migration sadece DB'de — server kodunda henüz değişiklik yok
# Bu adımda commit gerekli değil
```

---

## Task 2: Server — Consent Service

**Files:**
- Create: `qulo-server/src/services/consent.service.ts`

- [ ] **Step 1: consent.service.ts oluştur**

```typescript
import { supabase } from "../config/supabase.js";

type ConsentType = "terms_of_service" | "privacy_policy" | "kvkk_explicit";

interface RecordConsentInput {
  userId: string;
  consentType: ConsentType;
  version?: string;
  ipAddress?: string;
  appVersion?: string;
  platform?: string;
}

class ConsentService {
  async recordConsent(input: RecordConsentInput) {
    const { error } = await supabase.from("user_consents").upsert(
      {
        user_id: input.userId,
        consent_type: input.consentType,
        version: input.version ?? "1.0",
        ip_address: input.ipAddress,
        app_version: input.appVersion,
        platform: input.platform,
        accepted_at: new Date().toISOString(),
      },
      { onConflict: "user_id,consent_type,version" },
    );

    if (error) {
      console.error("[consent] Failed to record consent:", error.message);
    }
  }

  async recordRegistrationConsents(
    userId: string,
    ipAddress?: string,
    appVersion?: string,
    platform?: string,
  ) {
    const types: ConsentType[] = ["terms_of_service", "privacy_policy"];
    await Promise.all(
      types.map((consentType) =>
        this.recordConsent({ userId, consentType, ipAddress, appVersion, platform }),
      ),
    );
  }

  async getUserConsents(userId: string) {
    const { data, error } = await supabase
      .from("user_consents")
      .select("consent_type, version, accepted_at")
      .eq("user_id", userId)
      .order("accepted_at", { ascending: false });

    if (error) {
      console.error("[consent] Failed to get consents:", error.message);
      return [];
    }
    return data ?? [];
  }
}

export const consentService = new ConsentService();
```

- [ ] **Step 2: Commit**

```bash
git add src/services/consent.service.ts
git commit -m "feat(legal): add consent service for recording ToS/PP acceptance"
```

---

## Task 3: Server — Register Endpoint'e tos_accepted Ekle

**Files:**
- Modify: `qulo-server/src/validators/auth.validator.ts:3-14`
- Modify: `qulo-server/src/services/auth.service.ts:12-89`

- [ ] **Step 1: Validator'a tos_accepted ekle**

`auth.validator.ts` — registerSchema'ya ekle:

```typescript
export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1),
  surname: z.string().min(1),
  age: z.number().int().min(18).max(99),
  gender: z.enum(["MAN", "WOMAN", "OTHER"]),
  locale: z.enum(["tr", "en"]).default("tr"),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  referral_code: z.string().min(1).max(10).optional(),
  tos_accepted: z.literal(true, {
    errorMap: () => ({ message: "Terms of Service must be accepted" }),
  }),
});
```

- [ ] **Step 2: auth.service.ts — register metodunda consent kaydet**

`auth.service.ts` içinde, user insert başarılı olduktan sonra (satır 58 civarı), referral code bloğundan önce:

```typescript
// Record ToS + Privacy Policy consent (non-blocking)
import { consentService } from "./consent.service.js";

// ... register metodu içinde, user insert sonrası:
consentService.recordRegistrationConsents(user.id).catch((err) => {
  console.error("[auth] Failed to record consents:", err);
});
```

Import'u dosyanın üstüne ekle. `recordRegistrationConsents` çağrısını user insert sonrasına, referral code bloğundan hemen önce ekle.

- [ ] **Step 3: hardDeleteUser'a user_consents ekle**

`auth.service.ts` — `hardDeleteUser` metodundaki `childTables` dizisine ekle (refresh_tokens'dan önce):

```typescript
{ table: "user_consents", column: "user_id" },
```

Not: FK'da `ON DELETE CASCADE` var ama mevcut pattern tutarlılığı için manual delete de ekliyoruz.

- [ ] **Step 4: Server'ı başlatarak doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build
```

Hatasız build olmalı.

- [ ] **Step 5: Commit**

```bash
git add src/validators/auth.validator.ts src/services/auth.service.ts
git commit -m "feat(legal): require tos_accepted in register and record consent"
```

---

## Task 4: Flutter — Register Payload'a tos_accepted Ekle

**Files:**
- Modify: `qulov2/lib/data/repositories/auth_repository.dart:26-37`
- Modify: `qulov2/lib/providers/auth_provider.dart:149-176`
- Modify: `qulov2/lib/features/auth/mixins/register_screen_mixin.dart:262-278`

- [ ] **Step 1: AuthRepository — payload'a tos_accepted ekle**

`auth_repository.dart` satır 26-37, register metodundaki map'e ekle:

```dart
final response = await _service.register({
  'email': email,
  'password': password,
  'name': name,
  'surname': surname,
  'age': age,
  'gender': gender,
  'locale': locale,
  'tos_accepted': true,  // <-- YENİ
  if (lat != null) 'lat': lat,
  if (lng != null) 'lng': lng,
  if (referralCode != null) 'referral_code': referralCode,
});
```

Not: `tos_accepted` her zaman `true` gönderilir çünkü UI'da checkbox kontrolü zaten yapılıyor. Server tarafında `z.literal(true)` ile doğrulanıyor.

- [ ] **Step 2: flutter analyze ile doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze
```

Sıfır hata olmalı.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/auth_repository.dart
git commit -m "feat(legal): send tos_accepted=true in register payload"
```

---

## Task 5: Settings Ekranına Legal Bölümü Ekle

**Files:**
- Create: `qulov2/lib/features/settings/widgets/settings_legal_section.dart`
- Modify: `qulov2/lib/features/settings/screens/settings_screen.dart`

- [ ] **Step 1: settings_legal_section.dart oluştur**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/widgets/settings_action_tile.dart';

class SettingsLegalSection extends StatelessWidget {
  final Future<void> Function(String url) onOpenUrl;

  const SettingsLegalSection({super.key, required this.onOpenUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsActionTile(
          icon: Icons.description_outlined,
          title: context.tr('terms_of_service'),
          onTap: () => onOpenUrl('https://qulo.app/terms'),
        ),
        SettingsActionTile(
          icon: Icons.privacy_tip_outlined,
          title: context.tr('privacy_policy'),
          onTap: () => onOpenUrl('https://qulo.app/privacy'),
        ),
      ],
    );
  }
}
```

**Not:** `SettingsActionTile.onTap` tipi `Future<void> Function()` olduğu için `onOpenUrl` de `Future<void>` dönmeli. `UrlLauncherManager.launch` zaten `Future` döner, tip uyumu sağlanır.

- [ ] **Step 2: settings_screen.dart'a Legal section ekle**

`settings_screen.dart` — SettingsThemeTile ve _HapticTile'dan sonra, logout'tan önce ekle:

```dart
// Import ekle:
import 'package:qulo_v2/features/settings/widgets/settings_legal_section.dart';

// ListView children içinde, _HapticTile()'dan sonra:
const SizedBox(height: AppSpacing.sm),
SettingsLegalSection(onOpenUrl: onOpenUrl),
```

`onOpenUrl` callback'ini `SettingsScreenMixin`'de tanımla (`UrlLauncherManager` ile).

- [ ] **Step 3: SettingsScreenMixin'e onOpenUrl ekle**

`settings_screen_mixin.dart` dosyasına ekle:

Import ekle (dosyanın üstüne):
```dart
import 'package:qulo_v2/providers/api_provider.dart';
```

Metodu mixin'e ekle:
```dart
Future<void> onOpenUrl(String url) {
  return ref.read(urlLauncherManagerProvider).launch(url);
}
```

- [ ] **Step 4: flutter analyze ile doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/widgets/settings_legal_section.dart lib/features/settings/screens/settings_screen.dart lib/features/settings/mixins/settings_screen_mixin.dart
git commit -m "feat(legal): add Terms & Privacy links to Settings screen"
```

---

## Task 6: Web — KVKK Bölümlerini ToS ve PP'ye Ekle

**Files:**
- Modify: `web/src/lib/i18n/dictionaries/tr.json` — termsOfService + privacyPolicy
- Modify: `web/src/lib/i18n/dictionaries/en.json` — termsOfService + privacyPolicy
- Modify: `web/src/app/[locale]/terms/page.tsx` — KVKK section ekle
- Modify: `web/src/app/[locale]/privacy-policy/page.tsx` — KVKK section ekle

- [ ] **Step 1: ToS sayfasına KVKK bölümü ekle**

`terms/page.tsx` — sections dizisine ekle (governing'den sonra, contact'tan önce):

```typescript
{ title: "kvkkTitle", body: "kvkk" },
{ title: "dataProtectionTitle", body: "dataProtection" },
```

- [ ] **Step 2: Privacy Policy sayfasına KVKK bölümü ekle**

`privacy-policy/page.tsx` — sections dizisine ekle (changes'dan sonra, contact'tan önce):

```typescript
{ title: "kvkkTitle", body: "kvkk" },
{ title: "kvkkRightsTitle", body: "kvkkRights" },
```

- [ ] **Step 3: tr.json — termsOfService'e KVKK metni ekle**

Mevcut `contactTitle` "13. İletişim" → "15. İletişim" olarak güncellenmeli (renumber).

```json
"kvkkTitle": "13. KVKK Uyumu",
"kvkk": "Bu Kullanım Koşulları, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında hazırlanmıştır. Veri sorumlusu sıfatıyla Berkant Çalıkuşu, kişisel verilerinizi KVKK'nın öngördüğü ilkelere uygun olarak işlemektedir.\n\nKişisel verileriniz; hizmetin sunulması, yasal yükümlülüklerin yerine getirilmesi ve meşru menfaatlerimiz kapsamında işlenmektedir. Detaylı bilgi için Gizlilik Politikamızı inceleyiniz.",
"dataProtectionTitle": "14. Veri Koruma ve Yurt Dışı Aktarım",
"dataProtection": "Kişisel verileriniz, hizmet altyapımız gereği yurt dışında bulunan sunucularda (Supabase, Firebase, RevenueCat) işlenebilmektedir. Bu aktarım, KVKK madde 9 kapsamında açık rızanıza dayanmaktadır.\n\nVerilerinizin güvenliği için endüstri standardı şifreleme yöntemleri kullanılmaktadır.",
"contactTitle": "15. İletişim"
```

- [ ] **Step 4: en.json — termsOfService'e KVKK metni ekle**

Mevcut `contactTitle` "13. Contact" → "15. Contact" olarak güncellenmeli (renumber).

```json
"kvkkTitle": "13. Turkish Data Protection (KVKK)",
"kvkk": "These Terms of Service are prepared in compliance with the Turkish Personal Data Protection Law No. 6698 (KVKK). As the data controller, Berkant Çalıkuşu processes your personal data in accordance with the principles set forth by KVKK.\n\nYour personal data is processed for the purposes of providing the service, fulfilling legal obligations, and our legitimate interests. Please review our Privacy Policy for detailed information.",
"dataProtectionTitle": "14. Data Protection & International Transfers",
"dataProtection": "Your personal data may be processed on servers located outside of Turkey (Supabase, Firebase, RevenueCat) as required by our service infrastructure. This transfer is based on your explicit consent under KVKK Article 9.\n\nIndustry-standard encryption methods are used to ensure the security of your data.",
"contactTitle": "15. Contact"
```

- [ ] **Step 5: tr.json — privacyPolicy'ye KVKK hakları ekle**

```json
"kvkkTitle": "KVKK Kapsamında Haklarınız",
"kvkk": "6698 sayılı KVKK'nın 11. maddesi kapsamında aşağıdaki haklara sahipsiniz:\n\n• Kişisel verilerinizin işlenip işlenmediğini öğrenme\n• İşlenmişse buna ilişkin bilgi talep etme\n• İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme\n• Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme\n• Eksik veya yanlış işlenmişse düzeltilmesini isteme\n• KVKK madde 7 kapsamında silinmesini veya yok edilmesini isteme\n• Düzeltme/silme işlemlerinin aktarıldığı üçüncü kişilere bildirilmesini isteme\n• İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme\n• Kanuna aykırı olarak işlenmesi sebebiyle zarara uğramanız hâlinde zararın giderilmesini talep etme\n\nBaşvurularınız için: info@socrepho.com",
"kvkkRightsTitle": "Veri Sorumlusuna Başvuru",
"kvkkRights": "Veri Sorumlusu: Berkant Çalıkuşu\nAdres: İstanbul, Türkiye\nE-posta: info@socrepho.com\n\nBaşvurularınızı yukarıdaki e-posta adresine iletebilirsiniz. Talepleriniz en geç 30 gün içinde ücretsiz olarak sonuçlandırılacaktır. İşlemin ayrıca bir maliyet gerektirmesi hâlinde, KVKK Kurulu tarafından belirlenen tarife üzerinden ücret alınabilir."
```

- [ ] **Step 6: en.json — privacyPolicy'ye KVKK rights ekle**

```json
"kvkkTitle": "Your Rights Under Turkish KVKK",
"kvkk": "Under Article 11 of the Turkish Personal Data Protection Law (KVKK No. 6698), you have the following rights:\n\n• Learn whether your personal data is being processed\n• Request information about processing if it has been processed\n• Learn the purpose of processing and whether it is used accordingly\n• Know the third parties to whom your data is transferred domestically or abroad\n• Request correction of incomplete or inaccurate data\n• Request deletion or destruction under KVKK Article 7\n• Request notification of correction/deletion to third parties\n• Object to a result arising against you through automated analysis\n• Claim compensation for damages caused by unlawful processing\n\nFor inquiries: info@socrepho.com",
"kvkkRightsTitle": "Data Controller Contact",
"kvkkRights": "Data Controller: Berkant Çalıkuşu\nAddress: Istanbul, Turkey\nEmail: info@socrepho.com\n\nYou may submit your requests to the email address above. Your requests will be processed free of charge within 30 days at the latest. If the process requires additional costs, fees may be charged based on the tariff determined by the KVKK Board."
```

- [ ] **Step 7: Diğer diller için de aynı key'leri ekle (en.json kopyası)**

Diğer dil dosyalarına (16+ dil) şu key'leri ekle (en.json'daki İngilizce değerleri kopyala):

**termsOfService bölümüne:** `kvkkTitle`, `kvkk`, `dataProtectionTitle`, `dataProtection` key'leri + `contactTitle`'ı "15." olarak güncelle.

**privacyPolicy bölümüne:** `kvkkTitle`, `kvkk`, `kvkkRightsTitle`, `kvkkRights` key'leri.

Yerelleştirme sonra yapılabilir — şimdilik İngilizce metin yeterli.

- [ ] **Step 8: Commit**

```bash
git add web/src/lib/i18n/dictionaries/ web/src/app/
git commit -m "feat(legal): add KVKK sections to Terms and Privacy Policy pages"
```

---

## Task 7: Doğrulama ve Son Kontrol

- [ ] **Step 1: Server build doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build
```

- [ ] **Step 2: Flutter analyze doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze
```

- [ ] **Step 3: Web build doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/web && npm run build
```

- [ ] **Step 4: Manuel test checklist**

- [ ] Register endpoint'e `tos_accepted: true` göndererek kayıt olunabildiğini doğrula
- [ ] Register endpoint'e `tos_accepted: false` veya `tos_accepted` olmadan göndererek 400 aldığını doğrula
- [ ] `user_consents` tablosunda kayıt oluştuğunu doğrula
- [ ] Settings ekranında Terms of Service ve Privacy Policy linklerinin açıldığını doğrula
- [ ] Web'de `/tr/terms` ve `/tr/privacy-policy` sayfalarında KVKK bölümlerinin göründüğünü doğrula

---

## Kapsam Dışı (Gelecek İterasyonlar)

Aşağıdakiler bu plan kapsamında DEĞİL ama backlog'a eklenebilir:

1. **KVKK Açık Rıza Metni** — ayrı web sayfası + ayrı consent checkbox (hukuk danışmanı ile)
2. **Consent versiyonlama** — ToS güncellendiğinde mevcut kullanıcılara tekrar onay gösterme
3. **Apple Guideline 5.1.2(i)** — AI feature kullanımı için modal dialog (discover algoritması için)
4. **App Store / Play Console Privacy Labels** — store dashboardlarında doldurulacak formlar
5. **VERBIS kaydı** — KVKK Veri Sorumluları Sicili'ne kayıt
6. **IP adresi loglama** — consent kaydında request IP'si (Express `req.ip`)
