# Power Bulk Purchase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Satin alma sonrasi bottom sheet kapanmasin, kullanici istedigini alip kendisi kapatsin, basarili alimda sayac animasyonu oynasn.

**Architecture:** Sadece UI degisikligi — `pop()` cagrilarini kaldir, `_PowerRow` widget'ini StatefulWidget'a cevir ve AnimationController ile sayac uzerinde scale+glow animasyonu ekle. API/model/provider degisikligi yok.

**Tech Stack:** Flutter, Riverpod, AnimationController

---

## File Structure

| Dosya | Islem | Sorumluluk |
|-------|-------|-----------|
| `lib/features/quiz/widgets/power_purchase_sheet.dart` | Modify | Basari sonrasi `pop()` kaldir, `_PowerRow`'a animasyon ekle |
| `lib/features/exchange/widgets/power_shop_card.dart` | Modify | Basari SnackBar'i guncelle (zaten kapanmiyor) |

---

### Task 1: PowerPurchaseSheet — basari sonrasi pop() kaldir

**Files:**
- Modify: `lib/features/quiz/widgets/power_purchase_sheet.dart:34-65`

- [ ] **Step 1: `_onBuy` metodundaki basari `pop()` satirini kaldir**

`power_purchase_sheet.dart` dosyasinda `_onBuy` metodunu su sekilde degistir:

```dart
Future<void> _onBuy(String powerName, String diamondType) async {
  final key = '${powerName}_$diamondType';
  if (_buyingKey != null) return;
  setState(() => _buyingKey = key);

  final result = await ref
      .read(exchangeProvider.notifier)
      .buyPower(powerName, diamondType, 1);

  if (!mounted) return;

  result.when(
    success: (_) {
      // Sheet kapanmaz — kullanici istedigini alip kendisi kapatir
    },
    failure: (f) {
      if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
        Navigator.of(context).pop();
        PaywallBottomSheetContent.show(ref, trigger: 'power_purchase');
        return;
      }
      final message = f.message ?? context.tr('purchase_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.appColors.error,
        ),
      );
    },
  );
  setState(() => _buyingKey = null);
}
```

Degisiklik: `success` callback'indeki `Navigator.of(context).pop()` satirini bos birak. `failure` tarafindaki `INSUFFICIENT_DIAMONDS` pop'u aynen kalir.

- [ ] **Step 2: Flutter analyze calistir**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/quiz/widgets/power_purchase_sheet.dart
git commit -m "feat(power): keep purchase sheet open after successful buy"
```

---

### Task 2: _PowerRow'a basari animasyonu ekle (scale-up + glow pulse)

**Files:**
- Modify: `lib/features/quiz/widgets/power_purchase_sheet.dart:155-267`

- [ ] **Step 1: `_PowerRow`'u StatefulWidget'a cevir ve AnimationController ekle**

`_PowerRow` sinifiniin tamamini su sekilde degistir:

```dart
class _PowerRow extends StatefulWidget {
  final ExchangeRatePower power;
  final int inventoryCount;
  final String? buyingKey;
  final Future<void> Function(String powerName, String diamondType) onBuy;

  const _PowerRow({
    required this.power,
    required this.inventoryCount,
    required this.buyingKey,
    required this.onBuy,
  });

  @override
  State<_PowerRow> createState() => _PowerRowState();
}

class _PowerRowState extends State<_PowerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.inventoryCount;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_pulseController);
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant _PowerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inventoryCount > _previousCount) {
      _pulseController.forward(from: 0);
    }
    _previousCount = widget.inventoryCount;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerType = PowerType.fromApiName(widget.power.name);
    if (powerType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Animated power icon with glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _pulseController.isAnimating
                        ? [
                            BoxShadow(
                              color: powerType.color
                                  .withValues(alpha: _glowAnimation.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: PowerIcon(
                type: powerType,
                size: 28,
                showCount: widget.inventoryCount > 0,
                count: widget.inventoryCount,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _powerLabel(context),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _powerDesc(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Purple buy button
            _BuyChip(
              cost: widget.power.purpleCost,
              icon: const DiamondIcon.purple(size: 14, showGlow: false),
              isLoading: widget.buyingKey == '${widget.power.name}_PURPLE',
              onTap: () => widget.onBuy(widget.power.name, 'PURPLE'),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Green buy button
            _BuyChip(
              cost: widget.power.greenCost,
              icon: const DiamondIcon.green(size: 14, showGlow: false),
              isLoading: widget.buyingKey == '${widget.power.name}_GREEN',
              onTap: () => widget.onBuy(widget.power.name, 'GREEN'),
            ),
          ],
        ),
      ),
    );
  }

  String _powerLabel(BuildContext context) {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle',
      'HALF' => 'power_half',
      'SKIP' => 'power_skip',
      'SKIP_ALL' => 'power_skip_all',
      'TIME_EXTEND' => 'power_time',
      'HINT' => 'power_hint',
      'POWER_BLOCK' => 'power_block',
      'POWER_UNBLOCK' => 'power_unblock',
      _ => widget.power.name,
    };
    return context.tr(key);
  }

  String _powerDesc(BuildContext context) {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle_desc',
      'HALF' => 'power_half_desc',
      'SKIP' => 'power_skip_desc',
      'SKIP_ALL' => 'power_skip_all_desc',
      'TIME_EXTEND' => 'power_time_extend_desc',
      'HINT' => 'power_hint_desc',
      'POWER_BLOCK' => 'power_block_desc',
      'POWER_UNBLOCK' => 'power_unblock_desc',
      _ => '',
    };
    return key.isEmpty ? '' : context.tr(key);
  }
}
```

NOT: `AnimatedBuilder` Flutter'da yok — dogru sinif adi `AnimatedBuilder` degil, `AnimatedBuilder` kullanilmaz. Bunun yerine dogru API `AnimatedBuilder` sinifidir. DUZELTME: Flutter'da dogru sinif `AnimatedBuilder`. Ancak daha okunakli olarak `ListenableBuilder` veya direkt `AnimatedBuilder` kullanilabilir.

DUZELTME: Flutter'daki dogru widget adi `AnimatedBuilder`'dir. Bu widget `animation` parametresi alir ve her frame'de `builder` callback'ini cagirir.

- [ ] **Step 2: Flutter analyze calistir**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/quiz/widgets/power_purchase_sheet.dart
git commit -m "feat(power): add scale+glow pulse animation on purchase success"
```

---

### Task 3: PowerShopCard'da basari feedback'ini guncelle

**Files:**
- Modify: `lib/features/exchange/widgets/power_shop_card.dart:29-110`

PowerShopCard zaten sheet degil (card UI), kapanma sorunu yok. Ancak mevcut akis basarida SnackBar gosteriyor — tutarlilik icin animasyon ekleyelim.

- [ ] **Step 1: `_PowerShopCardState`'e `SingleTickerProviderStateMixin` ve animasyon ekle**

`_PowerShopCardState` sinifinin tamamini su sekilde degistir:

```dart
class _PowerShopCardState extends ConsumerState<PowerShopCard>
    with SingleTickerProviderStateMixin {
  String? _buyingWith; // 'purple' or 'green' or null
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  int _previousCount = 0;

  PowerType get _powerType =>
      PowerType.fromApiName(widget.power.name) ?? PowerType.oracle;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.inventoryCount;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_pulseController);
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant PowerShopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inventoryCount > _previousCount) {
      _pulseController.forward(from: 0);
    }
    _previousCount = widget.inventoryCount;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _powerLabel {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle',
      'HALF' => 'power_half',
      'SKIP' => 'power_skip',
      'SKIP_ALL' => 'power_skip_all',
      'TIME_EXTEND' => 'power_time',
      'HINT' => 'power_hint',
      _ => widget.power.name,
    };
    return context.tr(key);
  }

  String get _powerDesc {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle_desc',
      'HALF' => 'power_half_desc',
      'SKIP' => 'power_skip_desc',
      'SKIP_ALL' => 'power_skip_all_desc',
      'TIME_EXTEND' => 'power_time_extend_desc',
      'HINT' => 'power_hint_desc',
      _ => '',
    };
    return context.tr(key);
  }

  Future<void> _onBuy(String diamondType) async {
    if (_buyingWith != null) return;
    setState(() => _buyingWith = diamondType);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(widget.power.name, diamondType.toUpperCase(), 1);

    if (mounted) {
      result.when(
        success: (_) {
          // Animasyon didUpdateWidget'ta otomatik tetiklenir
          // SnackBar gostermiyoruz — glow + scale animasyonu yeterli feedback
        },
        failure: (f) {
          if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
            final params = f.params as Map<String, dynamic>?;
            final required = params?['required'] ?? '';
            final current = params?['current'] ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('purchase_insufficient_diamonds')
                      .replaceAll('{required}', '$required')
                      .replaceAll('{current}', '$current'),
                ),
                backgroundColor: context.appColors.error,
                action: SnackBarAction(
                  label: context.tr('purchase_get_diamonds'),
                  textColor: Colors.white,
                  onPressed: () {
                    ref
                        .read(navigationServiceProvider)
                        .go(RouteNames.diamonds);
                  },
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? context.tr('purchase_failed')),
                backgroundColor: context.appColors.error,
              ),
            );
          }
        },
      );
      setState(() => _buyingWith = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Animated power icon with glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _pulseController.isAnimating
                      ? [
                          BoxShadow(
                            color: _powerType.color
                                .withValues(alpha: _glowAnimation.value),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: PowerIcon(
              type: _powerType,
              size: 32,
              showCount: widget.inventoryCount > 0,
              count: widget.inventoryCount,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _powerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _powerDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Buy buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BuyButton(
                cost: widget.power.purpleCost,
                icon: const DiamondIcon.purple(size: 16, showGlow: false),
                isLoading: _buyingWith == 'purple',
                onTap: () => _onBuy('purple'),
              ),
              const SizedBox(height: AppSpacing.xs),
              _BuyButton(
                cost: widget.power.greenCost,
                icon: const DiamondIcon.green(size: 16, showGlow: false),
                isLoading: _buyingWith == 'green',
                onTap: () => _onBuy('green'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Flutter analyze calistir**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/exchange/widgets/power_shop_card.dart
git commit -m "feat(power): add purchase success animation to PowerShopCard"
```

---

### Task 4: Manuel test ve final commit

- [ ] **Step 1: Test senaryolari**

Cihazda/simulatorde su adimlari test et:

1. **Profil → Guc envanteri → tap → PowerPurchaseSheet acilir**
   - Bir guc al → sheet KAPANMAMALI
   - Guc ikonu scale-up + glow pulse oynamali
   - Bakiye ve envanter guncellenmeli
   - Baska bir guc al → ayni davranis
   - Sheet'i elle kapat (drag down veya disari tap)

2. **Exchange ekrani → PowerShopCard**
   - Bir guc al → animasyon oynamali
   - Envanter guncellenmeli

3. **Yetersiz bakiye senaryosu**
   - Bakiye yetmezken al → sheet kapanir, Paywall acilir (mevcut davranis korunmali)

4. **Hata senaryosu**
   - Network hatasi → SnackBar gosterilir, sheet acik kalir

- [ ] **Step 2: flutter analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: No issues found
