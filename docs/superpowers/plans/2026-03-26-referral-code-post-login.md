# Referral Code Post-Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Referral kodu girişini register akışından kaldırıp, login sonrası Diamonds ekranındaki referral kartına taşımak. Tek seferlik kullanım, deep link desteği.

**Architecture:** Backend'e 2 yeni endpoint eklenir (POST /apply, GET /my-referrer). Flutter'da register akışından referral temizlenir, ReferralInviteCard genişletilir, deep link akışı güncellenir.

**Tech Stack:** Node.js/Express/TypeScript (server), Flutter/Riverpod/Retrofit (client), Supabase PostgreSQL (DB)

**Spec:** `docs/superpowers/specs/2026-03-26-referral-code-post-login-design.md`

---

### Task 1: Backend — Yeni endpoint'ler ekle

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/routes/referral.routes.ts`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/services/referral.service.ts`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/validators/referral.validator.ts`

- [ ] **Step 1: `referral.validator.ts`'e `applyCodeSchema` ekle**

`validateCodeSchema`'nın hemen altına ekle:

```typescript
export const applyCodeSchema = z.object({
  code: z.string().min(1).max(10).transform((v) => v.toUpperCase()),
});

export type ApplyCodeInput = z.infer<typeof applyCodeSchema>;
```

- [ ] **Step 2: `referral.service.ts`'e `getMyReferrer` metodu ekle**

`validateCode` metodunun altına (class içinde, `}` kapanışından önce) ekle:

```typescript
  async getMyReferrer(userId: string) {
    const { data: referral } = await supabase
      .from("referrals")
      .select("referrer_id, status")
      .eq("referee_id", userId)
      .maybeSingle();

    if (!referral) {
      return { referrerName: null, status: null };
    }

    const { data: referrer } = await supabase
      .from("users")
      .select("name")
      .eq("id", referral.referrer_id)
      .single();

    return {
      referrerName: referrer?.name ?? "Unknown",
      status: referral.status,
    };
  }
```

- [ ] **Step 3: `referral.routes.ts`'e `POST /apply` ve `GET /my-referrer` endpoint'lerini ekle**

Import satırına `applyCodeSchema` ekle:

```typescript
import { validateCodeSchema, applyCodeSchema } from "../validators/referral.validator.js";
```

`POST /validate-code` route'unun altına (dosya sonundaki `export default router;`'dan önce) ekle:

```typescript
// POST /apply — apply a referral code (post-login, one-time)
router.post("/apply", validate(applyCodeSchema), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { code } = req.body;
    const result = await referralService.applyReferralCode(req.user!.userId, code);
    res.json({ referrerName: result.referrerName });
  } catch (err) {
    next(err);
  }
});

// GET /my-referrer — get who referred the current user
router.get("/my-referrer", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await referralService.getMyReferrer(req.user!.userId);
    res.json(result);
  } catch (err) {
    next(err);
  }
});
```

- [ ] **Step 4: Sunucuyu derle ve doğrula**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build`
Expected: Hatasız derleme

- [ ] **Step 5: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/routes/referral.routes.ts src/services/referral.service.ts src/validators/referral.validator.ts
git commit -m "feat(referral): add POST /apply and GET /my-referrer endpoints"
```

---

### Task 2: Flutter — Register akışından referral kodunu kaldır

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/auth/widgets/register_step_terms.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/auth/mixins/register_screen_mixin.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/auth/screens/register_screen.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/providers/auth_provider.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/auth_repository.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/interfaces.dart`

- [ ] **Step 1: `RegisterStepTerms`'den referral prop'larını kaldır**

`register_step_terms.dart` dosyasını düzenle. Şu prop'ları ve ilgili constructor parametrelerini kaldır:
- `referralCodeCtrl` (satır 19)
- `referralExpanded` (satır 20)
- `onToggleReferral` (satır 21)
- `onValidateReferral` (satır 22)
- `validatingReferral` (satır 23)
- `referralValidName` (satır 24)
- `referralError` (satır 25)

Constructor'dan karşılık gelen parametreleri kaldır:
- `this.referralCodeCtrl,` (satır 36)
- `this.referralExpanded = false,` (satır 37)
- `this.onToggleReferral,` (satır 38)
- `this.onValidateReferral,` (satır 39)
- `this.validatingReferral = false,` (satır 40)
- `this.referralValidName,` (satır 41)
- `this.referralError,` (satır 42)

Build metodundan referral bölümünü kaldır (satır 120-173 arası, `// ─── Referral Code` bloğunun tamamı). Ayrıca `AppLoadingWidget` ve `AppTextField` import'ları artık kullanılmıyorsa kaldır.

Sonuç olarak widget sadece terms checkbox + register butonu olacak.

- [ ] **Step 2: `RegisterScreenMixin`'den referral state ve logic'i kaldır**

`register_screen_mixin.dart` dosyasını düzenle:

Kaldırılacak alanlar:
- `final referralCodeCtrl = TextEditingController();` (satır 20)
- `bool referralExpanded = false;` (satır 33)
- `bool validatingReferral = false;` (satır 34)
- `String? referralValidName;` (satır 35 civarı — eğer farklı satırdaysa bulun)
- `String? referralError;` (satır 45)

`initMixin()` metodundan kaldır (satır 48-51):
```dart
    if (widget.referralCode != null && widget.referralCode!.isNotEmpty) {
      referralCodeCtrl.text = widget.referralCode!;
      referralExpanded = true;
    }
```

`disposeMixin()` metodundan kaldır (satır 60):
```dart
    referralCodeCtrl.dispose();
```

`validateReferralCode()` metodunu tamamen kaldır (satır 212-260).

`register()` metodundan kaldır (satır 267-268, 277):
```dart
    final referralCode = referralCodeCtrl.text.trim();
```
ve `referralCode: referralCode.isNotEmpty ? referralCode : null,` satırını kaldır.

`register()` metodu son hali (ilgili kısım):
```dart
    final result = await ref.read(authProvider.notifier).register(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          name: nameCtrl.text.trim(),
          surname: surnameCtrl.text.trim(),
          age: calculateAge(),
          gender: gender!,
          lat: lat,
          lng: lng,
        );
```

- [ ] **Step 3: `RegisterScreen`'den `referralCode` parametresini kaldır**

`register_screen.dart` dosyasını düzenle:

Kaldır:
```dart
  final String? referralCode;
```
ve constructor'dan `this.referralCode` parametresini kaldır:
```dart
  const RegisterScreen({super.key});
```

Build metodundan referral ile ilgili tüm satırları kaldır (satır 135-143):
```dart
                    referralCodeCtrl: referralCodeCtrl,
                    referralExpanded: referralExpanded,
                    onToggleReferral: () =>
                        setState(() => referralExpanded = !referralExpanded),
                    onValidateReferral: validateReferralCode,
                    validatingReferral: validatingReferral,
                    referralValidName: referralValidName,
                    referralError: referralError,
```

`RegisterStepTerms` çağrısı şöyle kalacak:
```dart
                  RegisterStepTerms(
                    termsAccepted: termsAccepted,
                    onTermsChanged: (value) {
                      setState(() {
                        termsAccepted = value ?? false;
                        termsError = null;
                      });
                    },
                    errorText: termsError,
                    isLoading: isLoading,
                    onRegister: register,
                    onTerms: () => context.push('/terms'),
                    onPrivacy: () => context.push('/privacy-policy'),
                  ),
```

- [ ] **Step 4: `AuthNotifier.register()`'dan `referralCode` parametresini kaldır**

`auth_provider.dart` satır 149-176 arasını düzenle:

```dart
  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    double? lat,
    double? lng,
    String locale = 'tr',
  }) async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterStart, params: {
      AnalyticsEvents.paramMethod: 'email',
    });
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(authRepositoryProvider).register(
      email: email,
      password: password,
      name: name,
      surname: surname,
      age: age,
      gender: gender,
      lat: lat,
      lng: lng,
      locale: locale,
    );
```

- [ ] **Step 5: `AuthRepository.register()` ve `IAuthRepository`'den `referralCode` kaldır**

`interfaces.dart` — `IAuthRepository.register()` imzasından `String? referralCode,` kaldır:
```dart
abstract class IAuthRepository {
  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    double? lat,
    double? lng,
    String locale = 'tr',
  });
```

`auth_repository.dart` — `register()` metodundan `String? referralCode,` parametresini ve request body'den `if (referralCode != null) 'referral_code': referralCode,` satırını kaldır:

```dart
  @override
  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    double? lat,
    double? lng,
    String locale = 'tr',
  }) async {
    try {
      final response = await _service.register({
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
        'age': age,
        'gender': gender,
        'locale': locale,
        'tos_accepted': true,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
```

- [ ] **Step 6: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata. Eğer hata varsa düzelt.

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/features/auth/ lib/providers/auth_provider.dart lib/data/repositories/auth_repository.dart lib/data/repositories/interfaces.dart
git commit -m "refactor(auth): remove referral code from registration flow"
```

---

### Task 3: Flutter — Referral model, service ve repository genişlet

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/models/referral_model.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/core/network/services/referral_service.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/referral_repository.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/interfaces.dart`

- [ ] **Step 1: `referral_model.dart`'a `MyReferrerResponse` model ekle**

Dosyanın sonuna (`ValidateCodeResponse` class'ının altına) ekle:

```dart
@JsonSerializable()
class MyReferrerResponse extends Equatable {
  @JsonKey(name: 'referrerName')
  final String? referrerName;
  final String? status;

  const MyReferrerResponse({
    this.referrerName,
    this.status,
  });

  factory MyReferrerResponse.fromJson(Map<String, dynamic> json) =>
      _$MyReferrerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyReferrerResponseToJson(this);

  @override
  List<Object?> get props => [referrerName, status];
}
```

- [ ] **Step 2: `referral_service.dart`'a yeni endpoint'leri ekle**

`validateCode` metodunun altına (abstract class içinde, kapanış `}`'dan önce) ekle:

```dart
  @POST('/referrals/apply')
  Future<dynamic> applyCode(@Body() Map<String, dynamic> data);

  @GET('/referrals/my-referrer')
  Future<MyReferrerResponse> getMyReferrer();
```

- [ ] **Step 3: build_runner çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart run build_runner build --delete-conflicting-outputs`
Expected: `referral_model.g.dart` ve `referral_service.g.dart` yeniden üretilir, hatasız.

- [ ] **Step 4: `IReferralRepository`'ye yeni metod imzaları ekle**

`interfaces.dart` dosyasında `IReferralRepository`'ye ekle (mevcut `validateCode` satırının altına):

```dart
  Future<Result<String>> applyCode(String code);
  Future<Result<MyReferrerResponse>> getMyReferrer();
```

- [ ] **Step 5: `ReferralRepository`'ye yeni metodları implement et**

`referral_repository.dart` dosyasında `validateCode` metodunun altına ekle:

```dart
  @override
  Future<Result<String>> applyCode(String code) async {
    try {
      final response = await _service.applyCode({'code': code});
      final name = response['referrerName'];
      if (name is! String) {
        return const Failure(UnknownFailure(message: 'Missing referrerName'));
      }
      return Success(name);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  @override
  Future<Result<MyReferrerResponse>> getMyReferrer() async {
    try {
      final response = await _service.getMyReferrer();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
```

- [ ] **Step 6: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/data/models/referral_model.dart lib/data/models/referral_model.g.dart lib/core/network/services/referral_service.dart lib/core/network/services/referral_service.g.dart lib/data/repositories/referral_repository.dart lib/data/repositories/interfaces.dart
git commit -m "feat(referral): add applyCode and getMyReferrer to service/repo layer"
```

---

### Task 4: Flutter — ReferralProvider state genişlet

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/providers/referral_provider.dart`

- [ ] **Step 1: `ReferralState`'i genişlet**

Mevcut `ReferralState` class'ını şununla değiştir:

```dart
class ReferralState extends Equatable {
  final String? code;
  final ReferralStats? stats;
  final List<ReferralItem> history;
  final String? referredBy;
  final String? referralStatus;

  const ReferralState({
    this.code,
    this.stats,
    this.history = const [],
    this.referredBy,
    this.referralStatus,
  });

  bool get hasAppliedCode => referredBy != null;

  ReferralState copyWith({
    String? code,
    ReferralStats? stats,
    List<ReferralItem>? history,
    String? referredBy,
    String? referralStatus,
  }) {
    return ReferralState(
      code: code ?? this.code,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      referredBy: referredBy ?? this.referredBy,
      referralStatus: referralStatus ?? this.referralStatus,
    );
  }

  @override
  List<Object?> get props => [code, stats, history, referredBy, referralStatus];
}
```

- [ ] **Step 2: `ReferralNotifier.fetchAll()`'i güncelle**

`fetchAll` metodunu şununla değiştir:

```dart
  Future<void> fetchAll() async {
    state = const AsyncLoading();

    final repo = ref.read(referralRepositoryProvider);
    final codeResult = await repo.getMyCode();
    final statsResult = await repo.getStats();
    final historyResult = await repo.getHistory();
    final referrerResult = await repo.getMyReferrer();

    String? code;
    ReferralStats? stats;
    List<ReferralItem> history = [];
    String? referredBy;
    String? referralStatus;

    codeResult.when(
      success: (data) => code = data,
      failure: (_) {},
    );
    statsResult.when(
      success: (data) => stats = data,
      failure: (_) {},
    );
    historyResult.when(
      success: (data) => history = data,
      failure: (_) {},
    );
    referrerResult.when(
      success: (data) {
        referredBy = data.referrerName;
        referralStatus = data.status;
      },
      failure: (_) {},
    );

    state = AsyncData(ReferralState(
      code: code,
      stats: stats,
      history: history,
      referredBy: referredBy,
      referralStatus: referralStatus,
    ));
  }
```

- [ ] **Step 3: `ReferralNotifier`'a `applyCode` metodu ekle**

`validateCode` metodunun altına ekle:

```dart
  Future<Result<String>> applyCode(String code) async {
    final result = await ref.read(referralRepositoryProvider).applyCode(code);
    result.when(
      success: (referrerName) {
        final current = state.valueOrNull ?? const ReferralState();
        state = AsyncData(current.copyWith(
          referredBy: referrerName,
          referralStatus: 'pending',
        ));
      },
      failure: (_) {},
    );
    return result;
  }
```

- [ ] **Step 4: Import ekle**

Dosyanın üstüne `MyReferrerResponse` import'u gerekli değil çünkü zaten `referral_model.dart` import ediliyor. Ancak `Result` import'unun mevcut olduğunu doğrula.

- [ ] **Step 5: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata

- [ ] **Step 6: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/providers/referral_provider.dart
git commit -m "feat(referral): extend ReferralState with referredBy and applyCode"
```

---

### Task 5: Flutter — ReferralInviteCard'a kod girme ve referred-by UI ekle

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/core/widgets/referral_invite_card.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/diamonds/widgets/diamonds_referral_section.dart`

- [ ] **Step 1: `ReferralInviteCard`'a yeni prop'lar ekle**

`referral_invite_card.dart`'ta `ReferralInviteCard` class'ına şu prop'ları ekle:

```dart
class ReferralInviteCard extends StatelessWidget {
  final String? code;
  final ReferralStats? stats;
  final bool compact;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  // Yeni prop'lar
  final String? referredBy;
  final String? referralStatus;
  final ValueChanged<String>? onApplyCode;
  final bool applyingCode;
  final String? applyError;
  final String? applySuccessName;

  const ReferralInviteCard({
    super.key,
    this.code,
    this.stats,
    this.compact = false,
    this.onShare,
    this.onTap,
    this.referredBy,
    this.referralStatus,
    this.onApplyCode,
    this.applyingCode = false,
    this.applyError,
    this.applySuccessName,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactCard(onTap: onTap);
    }
    return _FullCard(
      code: code,
      stats: stats,
      onShare: onShare,
      referredBy: referredBy,
      referralStatus: referralStatus,
      onApplyCode: onApplyCode,
      applyingCode: applyingCode,
      applyError: applyError,
      applySuccessName: applySuccessName,
    );
  }
}
```

- [ ] **Step 2: `_FullCard`'a yeni prop'ları ekle ve `_ReferredBySection` + `_ApplyCodeSection` widget'larını oluştur**

`_FullCard` class'ına prop'ları ekle:

```dart
class _FullCard extends StatelessWidget {
  final String? code;
  final ReferralStats? stats;
  final VoidCallback? onShare;
  final String? referredBy;
  final String? referralStatus;
  final ValueChanged<String>? onApplyCode;
  final bool applyingCode;
  final String? applyError;
  final String? applySuccessName;

  const _FullCard({
    this.code,
    this.stats,
    this.onShare,
    this.referredBy,
    this.referralStatus,
    this.onApplyCode,
    this.applyingCode = false,
    this.applyError,
    this.applySuccessName,
  });
```

`_FullCard`'ın build metodunun Column children'ına, progress bar'ın altına (son `ClipRRect`'ten sonra) şu bölümü ekle:

```dart
          const SizedBox(height: AppSpacing.lg),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Referred-by veya Apply-code bölümü
          if (referredBy != null)
            _ReferredBySection(
              referredBy: referredBy!,
              referralStatus: referralStatus,
            )
          else if (onApplyCode != null)
            _ApplyCodeSection(
              onApplyCode: onApplyCode!,
              isLoading: applyingCode,
              errorText: applyError,
              successName: applySuccessName,
            ),
```

- [ ] **Step 3: `_ReferredBySection` widget'ını oluştur**

Dosyanın sonuna ekle:

```dart
class _ReferredBySection extends StatelessWidget {
  final String referredBy;
  final String? referralStatus;

  const _ReferredBySection({
    required this.referredBy,
    this.referralStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = referralStatus == 'completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: context.appColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${context.tr('referral_invited_by')}$referredBy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCompleted
                ? context.tr('referral_reward_earned')
                : context.tr('referral_complete_profile'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCompleted
                  ? context.appColors.success
                  : Colors.amber.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: `_ApplyCodeSection` widget'ını oluştur**

Dosyanın sonuna ekle:

```dart
class _ApplyCodeSection extends StatefulWidget {
  final ValueChanged<String> onApplyCode;
  final bool isLoading;
  final String? errorText;
  final String? successName;

  const _ApplyCodeSection({
    required this.onApplyCode,
    this.isLoading = false,
    this.errorText,
    this.successName,
  });

  @override
  State<_ApplyCodeSection> createState() => _ApplyCodeSectionState();
}

class _ApplyCodeSectionState extends State<_ApplyCodeSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('referral_enter_code'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('referral_code_hint'),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.card_giftcard_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  errorText: widget.errorText,
                  errorStyle: TextStyle(color: context.appColors.error),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: widget.isLoading
                    ? null
                    : () {
                        final code = _controller.text.trim();
                        if (code.isNotEmpty) {
                          widget.onApplyCode(code);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                child: widget.isLoading
                    ? const AppLoadingWidget.small()
                    : Text(context.tr('referral_apply')),
              ),
            ),
          ],
        ),
        if (widget.successName != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.tr('referral_code_valid')}${widget.successName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.success,
            ),
          ),
        ],
      ],
    );
  }
}
```

`AppLoadingWidget` import'u dosyanın başına eklenmeli (eğer yoksa):
```dart
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
```

- [ ] **Step 5: `DiamondsReferralSection`'ı güncelle**

`diamonds_referral_section.dart` dosyasını şununla değiştir:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiamondsReferralSection extends ConsumerStatefulWidget {
  final String? prefillCode;

  const DiamondsReferralSection({super.key, this.prefillCode});

  @override
  ConsumerState<DiamondsReferralSection> createState() =>
      _DiamondsReferralSectionState();
}

class _DiamondsReferralSectionState
    extends ConsumerState<DiamondsReferralSection> {
  bool _applyingCode = false;
  String? _applyError;
  String? _applySuccessName;

  Future<void> _onApplyCode(String code) async {
    setState(() {
      _applyingCode = true;
      _applyError = null;
      _applySuccessName = null;
    });

    final result = await ref.read(referralProvider.notifier).applyCode(code);

    if (!mounted) return;

    result.when(
      success: (referrerName) {
        setState(() {
          _applyingCode = false;
          _applySuccessName = referrerName;
        });
      },
      failure: (f) {
        final errorCode = switch (f) {
          ServerFailure(:final code) => code,
          _ => 'UNKNOWN',
        };
        setState(() {
          _applyingCode = false;
          _applyError = context.tr(
            errorCode == 'SELF_REFERRAL'
                ? 'referral_self_error'
                : errorCode == 'ALREADY_REFERRED'
                    ? 'referral_already_error'
                    : 'referral_code_invalid',
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(referralProvider);

    return referralAsync.when(
      loading: () => const Center(child: AppLoadingWidget.small()),
      error: (_, __) => const SizedBox.shrink(),
      data: (referralState) => ReferralInviteCard(
        code: referralState.code,
        stats: referralState.stats,
        referredBy: _applySuccessName != null
            ? _applySuccessName
            : referralState.referredBy,
        referralStatus: _applySuccessName != null
            ? 'pending'
            : referralState.referralStatus,
        onApplyCode: referralState.hasAppliedCode || _applySuccessName != null
            ? null
            : _onApplyCode,
        applyingCode: _applyingCode,
        applyError: _applyError,
        applySuccessName: _applySuccessName,
        onShare: () {
          if (referralState.code != null) {
            final code = referralState.code!;
            final reward =
                ref.read(economyConfigProvider).rewards.referralPurple;
            final message =
                "Qulo'ya katıl! Davet kodumu kullan, ikimize de $reward mor elmas hediye: $code\nhttps://quloapp.com/invite/$code";
            ref.read(shareManagerProvider).share(message);
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 6: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/core/widgets/referral_invite_card.dart lib/features/diamonds/widgets/diamonds_referral_section.dart
git commit -m "feat(referral): add apply code input and referred-by display to referral card"
```

---

### Task 6: Flutter — Deep link akışını güncelle

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/routing/app_routes.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/routing/app_router.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/diamonds/screens/diamonds_screen.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/diamonds/mixins/diamonds_screen_mixin.dart`

- [ ] **Step 1: `app_routes.dart`'ta invite redirect'i güncelle**

`app_routes.dart` satır 29-36'daki invite route'unu şununla değiştir:

```dart
  // Invite deep link
  GoRoute(
    path: '/invite/:code',
    name: RouteNames.invite,
    redirect: (context, state) {
      final code = state.pathParameters['code'] ?? '';
      return '/profile/diamonds?referralCode=$code';
    },
  ),
```

- [ ] **Step 2: `app_router.dart`'ta invite redirect mantığını güncelle**

`app_router.dart`'ta redirect fonksiyonundaki invite ile ilgili kısımları güncelle.

Satır 86-87'deki mevcut:
```dart
      if (isAuth && isInviteRoute) return '/discover';
```
Bunu şununla değiştir:
```dart
      if (isAuth && isInviteRoute) {
        final code = state.pathParameters['code'] ?? '';
        return '/profile/diamonds?referralCode=$code';
      }
```

Satır 95-97'deki (auth değilken invite'a izin veren kısım):
```dart
      if (!isAuth && !isAuthRoute && !isInviteRoute && !isUpdateRoute) {
```
Bu satırda invite route auth gerektirmediği için `isInviteRoute` zaten exemption'da. Ama artık auth gerektiriyoruz. Güncelle:

```dart
      // Auth olmayan kullanıcılar için: invite link → pending olarak sakla
      if (!isAuth && isInviteRoute) {
        final code = state.pathParameters['code'] ?? '';
        if (code.isNotEmpty) {
          ref.read(pendingDeepLinkProvider.notifier).state =
              '/profile/diamonds?referralCode=$code';
        }
        return '/auth/login';
      }

      if (!isAuth && !isAuthRoute && !isUpdateRoute) {
        return '/auth/login';
      }
```

Not: `!isInviteRoute` koşulunu kaldırdık çünkü invite artık yukarıda handle ediliyor.

- [ ] **Step 3: `DiamondsScreen`'e `referralCode` query param desteği ekle**

`diamonds_screen.dart`'ta `DiamondsScreen` class'ını güncelle:

```dart
class DiamondsScreen extends ConsumerStatefulWidget {
  final String? referralCode;

  const DiamondsScreen({super.key, this.referralCode});

  @override
  ConsumerState<DiamondsScreen> createState() => _DiamondsScreenState();
}
```

Build metodunda `DiamondsReferralSection`'a `prefillCode` ekle:

```dart
            // Referral
            DiamondsReferralSection(
              prefillCode: widget.referralCode,
            ),
```

- [ ] **Step 4: `app_routes.dart`'ta diamonds route'unu güncelle**

Diamonds route'unu (satır 283-286 civarı) şununla değiştir:

```dart
            GoRoute(
              path: 'diamonds',
              name: RouteNames.diamonds,
              builder: (context, state) {
                final referralCode = state.uri.queryParameters['referralCode'];
                return DiamondsScreen(referralCode: referralCode);
              },
            ),
```

- [ ] **Step 5: `DiamondsReferralSection`'da prefillCode'u input'a pre-fill et**

`diamonds_referral_section.dart`'ta `_DiamondsReferralSectionState`'e `initState` ekle — eğer `prefillCode` varsa ve kullanıcı henüz referral code uygulamadıysa, `_ApplyCodeSection`'ın controller'ına pre-fill yapmak için state üzerinden ilet.

Bunun için `_ApplyCodeSection`'a `initialCode` prop'u ekle:

`referral_invite_card.dart`'ta `_ApplyCodeSection`'a:
```dart
  final String? initialCode;

  const _ApplyCodeSection({
    required this.onApplyCode,
    this.isLoading = false,
    this.errorText,
    this.successName,
    this.initialCode,
  });
```

`_ApplyCodeSectionState`'in `initState`'ine ekle:
```dart
  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _controller.text = widget.initialCode!;
    }
  }
```

`_FullCard`'a `initialCode` prop'u ekle ve `_ApplyCodeSection`'a ilet:
```dart
  final String? initialCode;
```

Constructor'a ekle, `_ApplyCodeSection` çağrısına `initialCode: initialCode,` ekle.

`ReferralInviteCard`'a da `initialCode` prop'u ekle ve `_FullCard`'a ilet.

`DiamondsReferralSection`'ın build metodundaki `ReferralInviteCard`'a `initialCode: widget.prefillCode,` ekle.

- [ ] **Step 6: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/routing/ lib/features/diamonds/ lib/core/widgets/referral_invite_card.dart
git commit -m "feat(referral): update deep link flow to redirect to diamonds screen"
```

---

### Task 7: i18n — Yeni çeviri anahtarları ekle

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/core/l10n/translations/tr.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/core/l10n/translations/en.dart`

- [ ] **Step 1: Türkçe çevirileri ekle**

`tr.dart` dosyasındaki map'e şu key'leri ekle (mevcut referral key'lerinin yanına):

```dart
    'referral_enter_code': 'Davet kodun var mı? Buraya gir:',
    'referral_apply': 'Uygula',
    'referral_invited_by': 'Davet eden: ',
    'referral_reward_earned': '25 mor elmas kazandın!',
    'referral_complete_profile': 'Profilini %60 tamamla, ödülünü kazan!',
    'referral_self_error': 'Kendi kodunu kullanamazsın',
    'referral_already_error': 'Zaten bir davet kodu kullandın',
```

- [ ] **Step 2: İngilizce çevirileri ekle**

`en.dart` dosyasındaki map'e şu key'leri ekle:

```dart
    'referral_enter_code': 'Have an invite code? Enter it here:',
    'referral_apply': 'Apply',
    'referral_invited_by': 'Invited by: ',
    'referral_reward_earned': 'You earned 25 purple diamonds!',
    'referral_complete_profile': 'Complete your profile to 60% to claim your reward!',
    'referral_self_error': 'You cannot use your own code',
    'referral_already_error': 'You have already used an invite code',
```

- [ ] **Step 3: Diğer dillere de ekle**

Tüm çeviri dosyalarına (`de.dart`, `fr.dart`, `es.dart`, `it.dart`, `pt.dart`, `ru.dart`, `ar.dart`, `ja.dart`, `ko.dart`, `zh.dart`, `nl.dart`, `pl.dart`, `sv.dart`, `hi.dart`) İngilizce değerleri fallback olarak ekle.

- [ ] **Step 4: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/core/l10n/
git commit -m "feat(i18n): add referral apply code translation keys"
```

---

### Task 8: Final doğrulama ve temizlik

- [ ] **Step 1: `flutter analyze` çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata

- [ ] **Step 2: Server build doğrula**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build`
Expected: Hatasız derleme

- [ ] **Step 3: Kullanılmayan import'ları temizle**

Register dosyalarında artık kullanılmayan import'lar varsa kaldır. Özellikle:
- `register_step_terms.dart` — `AppLoadingWidget` ve `AppTextField` import'ları kullanılmıyor olabilir
- `register_screen_mixin.dart` — `referral_provider` veya `referral_repository` import'u kaldırılmalı

- [ ] **Step 4: `flutter analyze` tekrar çalıştır**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: Sıfır hata, sıfır warning

- [ ] **Step 5: Final commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add -A
git commit -m "chore: cleanup unused imports after referral refactor"
```
