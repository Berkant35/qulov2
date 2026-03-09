# AppLoadingWidget Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Qulo Q logosundan custom loading animasyonu oluştur, AppScaffold'a entegre et ve tüm projede standart hale getir.

**Architecture:** CustomPainter ile Q logosu (daire + ok) çizilir, AnimationController ile döndürülür. Large varyantında mor neon glow eklenir. AppScaffold'a `isLoading` parametresi eklenerek tüm ekranlarda tek noktadan loading kontrolü sağlanır.

**Tech Stack:** Flutter CustomPainter, AnimationController, AppColors theme tokens

---

### Task 1: AppLoadingWidget — CustomPainter + Animasyon

**Files:**
- Create: `lib/core/widgets/app_loading_widget.dart`

**Step 1: AppLoadingWidget widget'ını oluştur**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class AppLoadingWidget extends StatefulWidget {
  final double size;
  final bool showGlow;

  const AppLoadingWidget({
    super.key,
    this.size = 48,
    this.showGlow = false,
  });

  const AppLoadingWidget.small({super.key})
      : size = 24,
        showGlow = false;

  const AppLoadingWidget.large({super.key})
      : size = 48,
        showGlow = true;

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.showGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _QLogoPainter(color: AppColors.primary);

    if (!widget.showGlow) {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: child,
          );
        },
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: painter,
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _glowController]),
      builder: (context, child) {
        final glow = _glowController.value;
        final glowSize = widget.size * (1.4 + glow * 0.3);

        return SizedBox(
          width: glowSize,
          height: glowSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20 + glow * 0.10),
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Rotating Q logo
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: child,
              ),
            ],
          ),
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: painter,
      ),
    );
  }
}

class _QLogoPainter extends CustomPainter {
  final Color color;

  _QLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final strokeWidth = size.width * 0.08;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Ana daire (Q'nun O kısmı) — açık arc, ok ucu için boşluk bırakır
    // Saat yönünde, sağ alttan başla, neredeyse tam daire (~300 derece)
    const startAngle = math.pi * 0.35; // ~63 derece (sağ alt)
    const sweepAngle = math.pi * 1.65; // ~297 derece

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Ok başı (arc'ın bitiş noktasında)
    final arrowAngle = startAngle + sweepAngle;
    final arrowTip = Offset(
      center.dx + math.cos(arrowAngle) * radius,
      center.dy + math.sin(arrowAngle) * radius,
    );

    final arrowSize = size.width * 0.12;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Ok üçgeni — arc yönüne göre
    final tangentAngle = arrowAngle + math.pi / 2; // Teğet yönü
    final p1 = Offset(
      arrowTip.dx + math.cos(tangentAngle) * arrowSize,
      arrowTip.dy + math.sin(tangentAngle) * arrowSize,
    );
    final p2 = Offset(
      arrowTip.dx + math.cos(arrowAngle + math.pi * 0.75) * arrowSize,
      arrowTip.dy + math.sin(arrowAngle + math.pi * 0.75) * arrowSize,
    );
    final p3 = Offset(
      arrowTip.dx + math.cos(arrowAngle - math.pi * 0.75) * arrowSize,
      arrowTip.dy + math.sin(arrowAngle - math.pi * 0.75) * arrowSize,
    );

    final arrowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(_QLogoPainter old) => old.color != color;
}
```

**Step 2: Flutter analyze ile kontrol et**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/widgets/app_loading_widget.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/widgets/app_loading_widget.dart
git commit -m "feat: add AppLoadingWidget with Q logo spin animation"
```

---

### Task 2: AppScaffold — isLoading Parametresi

**Files:**
- Modify: `lib/core/widgets/app_scaffold.dart`

**Step 1: AppScaffold'a isLoading parametresi ekle**

Değişiklikler:
1. `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';` ekle
2. `final bool isLoading;` field ekle
3. Constructor'a `this.isLoading = false` ekle
4. `build` metodunda body yerine loading widget göster:

```dart
// body kullanımını değiştir:
child: padding != null
    ? Padding(padding: padding!, child: isLoading
        ? const Center(child: AppLoadingWidget.large())
        : body)
    : isLoading
        ? const Center(child: AppLoadingWidget.large())
        : body,
```

**Step 2: Flutter analyze**

Run: `flutter analyze lib/core/widgets/app_scaffold.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/widgets/app_scaffold.dart
git commit -m "feat: add isLoading parameter to AppScaffold"
```

---

### Task 3: AppButton — Small Varyant Entegrasyonu

**Files:**
- Modify: `lib/core/widgets/app_button.dart`

**Step 1: CircularProgressIndicator'ı AppLoadingWidget.small() ile değiştir**

```dart
// Eski (satır 26-31):
final child = isLoading
    ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
      )

// Yeni:
final child = isLoading
    ? const SizedBox(
        height: 20,
        width: 20,
        child: AppLoadingWidget.small(),
      )
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 2: Commit**

```bash
git add lib/core/widgets/app_button.dart
git commit -m "feat: replace CircularProgressIndicator with AppLoadingWidget in AppButton"
```

---

### Task 4: Tam Sayfa Loading — Riverpod .when() Ekranları

Bu ekranlar `state.when(loading: () => CircularProgressIndicator())` pattern'i kullanıyor. AppScaffold'un `isLoading` parametresine taşınacak.

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/chat/screens/matches_screen.dart`
- Modify: `lib/features/chat/screens/chat_screen.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Modify: `lib/features/profile/screens/questions_screen.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: discover_screen.dart**

```dart
// Eski (satır 37-41):
return AppScaffold(
  title: context.tr('discover'),
  padding: EdgeInsets.zero,
  body: state.when(
    loading: () => const Center(child: CircularProgressIndicator()),

// Yeni:
return AppScaffold(
  title: context.tr('discover'),
  padding: EdgeInsets.zero,
  isLoading: state is AsyncLoading,
  body: state.when(
    loading: () => const SizedBox.shrink(),
```

**Step 2: matches_screen.dart**

```dart
// Eski (satır 32-36):
return AppScaffold(
  title: context.tr('matches'),
  padding: EdgeInsets.zero,
  body: matchesAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),

// Yeni:
return AppScaffold(
  title: context.tr('matches'),
  padding: EdgeInsets.zero,
  isLoading: matchesAsync is AsyncLoading,
  body: matchesAsync.when(
    loading: () => const SizedBox.shrink(),
```

**Step 3: chat_screen.dart**

Chat screen'de loading body'nin tamamında değil, sadece Expanded child'ında. Bu durumda doğrudan AppLoadingWidget kullanılacak.

```dart
// Eski (satır 85-86):
child: chatState.when(
  loading: () => const Center(child: CircularProgressIndicator()),

// Yeni:
child: chatState.when(
  loading: () => const Center(child: AppLoadingWidget.large()),
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 4: profile_screen.dart**

```dart
// Eski (satır 53-63):
return AppScaffold(
  title: context.tr('profile'),
  ...
  body: userAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),

// Yeni:
return AppScaffold(
  title: context.tr('profile'),
  ...
  isLoading: userAsync is AsyncLoading,
  body: userAsync.when(
    loading: () => const SizedBox.shrink(),
```

**Step 5: questions_screen.dart**

```dart
// Eski (satır 142-161):
return AppScaffold(
  title: context.tr('my_questions'),
  ...
  body: questionsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),

// Yeni:
return AppScaffold(
  title: context.tr('my_questions'),
  ...
  isLoading: questionsAsync is AsyncLoading,
  body: questionsAsync.when(
    loading: () => const SizedBox.shrink(),
```

**Step 6: quiz_screen.dart**

Quiz screen'de loading body bazlı değil, koşul bazlı (isLoading || question == null).

```dart
// Eski (satır 79-89):
return AppScaffold(
  ...
  body: quiz.isLoading || question == null
    ? const Center(child: CircularProgressIndicator())

// Yeni:
return AppScaffold(
  ...
  isLoading: quiz.isLoading || question == null,
  body: quiz.isLoading || question == null
    ? const SizedBox.shrink()
```

**Step 7: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart \
        lib/features/chat/screens/matches_screen.dart \
        lib/features/chat/screens/chat_screen.dart \
        lib/features/profile/screens/profile_screen.dart \
        lib/features/profile/screens/questions_screen.dart \
        lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat: replace CircularProgressIndicator with AppLoadingWidget across screens"
```

---

### Task 5: Inline Loading — Kısmi Alanlar

Bu dosyalarda loading widget tam sayfa değil, belirli bir alan/section için kullanılıyor. Bunlarda AppLoadingWidget doğrudan kullanılacak.

**Files:**
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`
- Modify: `lib/features/passport/screens/passport_screen.dart`
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`
- Modify: `lib/features/profile/widgets/photo_grid.dart`

**Step 1: diamonds_screen.dart**

```dart
// Satır 83 — balance loading:
// Eski:
loading: () => const Center(child: CircularProgressIndicator()),
// Yeni:
loading: () => const Center(child: AppLoadingWidget.large()),

// Satır 152 — history loading:
// Eski:
const Center(child: CircularProgressIndicator())
// Yeni:
const Center(child: AppLoadingWidget.large())
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 2: passport_screen.dart**

```dart
// Satır 71 — buton içi loading:
// Eski:
? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
// Yeni:
? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 3: edit_profile_screen.dart**

```dart
// Satır 536-539 — location button loading:
// Eski:
? const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
  )
// Yeni:
? const SizedBox(
    width: 20,
    height: 20,
    child: AppLoadingWidget.small(),
  )
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 4: photo_grid.dart**

```dart
// Satır 175-181 — image placeholder loading:
// Eski:
child: const Center(
  child: SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: AppColors.primary,
    ),
  ),
),
// Yeni:
child: const Center(
  child: AppLoadingWidget.small(),
),
```

Import ekle: `import 'package:qulo_v2/core/widgets/app_loading_widget.dart';`

**Step 5: Commit**

```bash
git add lib/features/diamonds/screens/diamonds_screen.dart \
        lib/features/passport/screens/passport_screen.dart \
        lib/features/profile/screens/edit_profile_screen.dart \
        lib/features/profile/widgets/photo_grid.dart
git commit -m "feat: replace inline CircularProgressIndicator with AppLoadingWidget"
```

---

### Task 6: Final Kontrol

**Step 1: Tüm projede kalan CircularProgressIndicator ara**

Run: `grep -r "CircularProgressIndicator" lib/`
Expected: Hiç sonuç olmamalı (veya sadece theme tanımında olabilir)

**Step 2: Flutter analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Final commit (gerekirse)**

```bash
git commit -m "chore: clean up remaining CircularProgressIndicator references"
```
