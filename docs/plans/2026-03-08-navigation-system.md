# Navigation System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Merkezi NavigationService ile tum route, dialog ve bottom sheet islemlerini tek noktadan yonetmek; observer pattern ile loglama/analytics altyapisi kurmak.

**Architecture:** GoRouter'i saran Riverpod-based NavigationService. Root/shell navigator key'leri ile bottom nav kontrolu. sealed class dialog/bottom sheet type system. Observer chain ile event notify.

**Tech Stack:** Flutter, GoRouter, Riverpod, Firebase Analytics (observer)

---

### Task 1: Navigation Event & Type Models

**Files:**
- Create: `lib/core/navigation/navigation_event.dart`

**Step 1: Create NavigationEvent model and NavigationType enum**

```dart
enum NavigationType { go, push, pop }

class NavigationEvent {
  final String routeName;
  final NavigationType type;
  final Map<String, String>? pathParameters;
  final Object? extra;
  final DateTime timestamp;

  const NavigationEvent({
    required this.routeName,
    required this.type,
    this.pathParameters,
    this.extra,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _Now();

  factory NavigationEvent.go(String routeName, {Map<String, String>? pathParameters, Object? extra}) =>
      NavigationEvent(routeName: routeName, type: NavigationType.go, pathParameters: pathParameters, extra: extra, timestamp: DateTime.now());

  factory NavigationEvent.push(String routeName, {Map<String, String>? pathParameters, Object? extra}) =>
      NavigationEvent(routeName: routeName, type: NavigationType.push, pathParameters: pathParameters, extra: extra, timestamp: DateTime.now());

  factory NavigationEvent.pop(String routeName) =>
      NavigationEvent(routeName: routeName, type: NavigationType.pop, timestamp: DateTime.now());

  @override
  String toString() => '[NAV] ${type.name} -> $routeName${pathParameters != null ? ' | params: $pathParameters' : ''}';
}
```

Note: `_Now` trick won't work — use nullable + assign in body:

```dart
NavigationEvent({
  required this.routeName,
  required this.type,
  this.pathParameters,
  this.extra,
  DateTime? timestamp,
}) : timestamp = timestamp ?? DateTime.now();
```

**Step 2: Verify file compiles**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/navigation_event.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/navigation/navigation_event.dart
git commit -m "feat: add NavigationEvent model and NavigationType enum"
```

---

### Task 2: Abstract NavigationObserver

**Files:**
- Create: `lib/core/navigation/navigation_observer.dart`

**Step 1: Create abstract class**

```dart
abstract class AppNavigationObserver {
  void onNavigate(NavigationEvent event) {}
  void onPop(NavigationEvent event) {}
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {}
  void onDialogClose(String dialogName, {dynamic result}) {}
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {}
  void onBottomSheetClose(String sheetName, {dynamic result}) {}
}
```

Note: Use `AppNavigationObserver` name to avoid conflict with Flutter's built-in `NavigatorObserver`. Methods have empty default bodies so subclasses only override what they need.

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/navigation_observer.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/navigation/navigation_observer.dart
git commit -m "feat: add abstract AppNavigationObserver"
```

---

### Task 3: LoggingObserver

**Files:**
- Create: `lib/core/navigation/observers/logging_observer.dart`

**Step 1: Implement LoggingObserver**

```dart
import 'package:flutter/foundation.dart';
import '../navigation_observer.dart';
import '../navigation_event.dart';

class LoggingObserver extends AppNavigationObserver {
  @override
  void onNavigate(NavigationEvent event) {
    if (kDebugMode) {
      debugPrint(event.toString());
    }
  }

  @override
  void onPop(NavigationEvent event) {
    if (kDebugMode) {
      debugPrint(event.toString());
    }
  }

  @override
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('[NAV] dialog_open -> $dialogName${params != null ? ' | $params' : ''}');
    }
  }

  @override
  void onDialogClose(String dialogName, {dynamic result}) {
    if (kDebugMode) {
      debugPrint('[NAV] dialog_close -> $dialogName | result: $result');
    }
  }

  @override
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('[NAV] sheet_open -> $sheetName${params != null ? ' | $params' : ''}');
    }
  }

  @override
  void onBottomSheetClose(String sheetName, {dynamic result}) {
    if (kDebugMode) {
      debugPrint('[NAV] sheet_close -> $sheetName | result: $result');
    }
  }
}
```

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/observers/logging_observer.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/navigation/observers/logging_observer.dart
git commit -m "feat: add LoggingObserver for debug navigation logs"
```

---

### Task 4: Dialog & BottomSheet Models (sealed classes)

**Files:**
- Create: `lib/core/navigation/models/app_dialog.dart`
- Create: `lib/core/navigation/models/app_bottom_sheet.dart`

**Step 1: Create AppDialog sealed class hierarchy**

```dart
// lib/core/navigation/models/app_dialog.dart
import 'package:flutter/material.dart';

sealed class AppDialog {
  final String name;
  final bool barrierDismissible;
  final bool useRootNavigator;

  const AppDialog({
    required this.name,
    this.barrierDismissible = true,
    this.useRootNavigator = true,
  });
}

class ConfirmDialog extends AppDialog {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    required super.name,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    super.barrierDismissible = false,
    super.useRootNavigator,
  });
}

class InfoDialog extends AppDialog {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? buttonText;

  const InfoDialog({
    required super.name,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.buttonText,
    super.barrierDismissible = false,
    super.useRootNavigator,
  });
}

class CustomDialog extends AppDialog {
  final Widget Function(BuildContext context) builder;

  const CustomDialog({
    required super.name,
    required this.builder,
    super.barrierDismissible,
    super.useRootNavigator,
  });
}
```

**Step 2: Create AppBottomSheet sealed class hierarchy**

```dart
// lib/core/navigation/models/app_bottom_sheet.dart
import 'package:flutter/material.dart';

sealed class AppBottomSheet {
  final String name;
  final bool isDismissible;
  final bool enableDrag;
  final bool useRootNavigator;
  final double? maxHeightFactor;

  const AppBottomSheet({
    required this.name,
    this.isDismissible = true,
    this.enableDrag = true,
    this.useRootNavigator = true,
    this.maxHeightFactor,
  });
}

class SheetOption<T> {
  final IconData? icon;
  final String label;
  final T value;

  const SheetOption({this.icon, required this.label, required this.value});
}

class ListBottomSheet<T> extends AppBottomSheet {
  final String? title;
  final List<SheetOption<T>> options;

  const ListBottomSheet({
    required super.name,
    this.title,
    required this.options,
    super.isDismissible,
    super.enableDrag,
    super.useRootNavigator,
    super.maxHeightFactor,
  });
}

class CustomBottomSheet extends AppBottomSheet {
  final Widget Function(BuildContext context) builder;

  const CustomBottomSheet({
    required super.name,
    required this.builder,
    super.isDismissible,
    super.enableDrag,
    super.useRootNavigator,
    super.maxHeightFactor,
  });
}
```

**Step 3: Verify both**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/models/`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/core/navigation/models/
git commit -m "feat: add sealed class dialog and bottom sheet models"
```

---

### Task 5: Dialog & BottomSheet Widget Renderers

**Files:**
- Create: `lib/core/navigation/widgets/confirm_dialog_widget.dart`
- Create: `lib/core/navigation/widgets/info_dialog_widget.dart`
- Create: `lib/core/navigation/widgets/list_bottom_sheet_widget.dart`

**Step 1: ConfirmDialog renderer**

```dart
// lib/core/navigation/widgets/confirm_dialog_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../models/app_dialog.dart';

class ConfirmDialogWidget extends StatelessWidget {
  final ConfirmDialog dialog;

  const ConfirmDialogWidget({super.key, required this.dialog});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(dialog.title),
      content: Text(dialog.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            dialog.cancelText ?? context.tr('cancel'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            dialog.confirmText ?? context.tr('confirm'),
            style: TextStyle(
              color: dialog.isDestructive ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
```

Note: Here `Navigator.of(context).pop()` is correct because `context` IS the dialog's own BuildContext (passed by the builder). The bug we fixed earlier was using the OUTER context, not the dialog's context.

**Step 2: InfoDialog renderer**

```dart
// lib/core/navigation/widgets/info_dialog_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../models/app_dialog.dart';

class InfoDialogWidget extends StatelessWidget {
  final InfoDialog dialog;

  const InfoDialogWidget({super.key, required this.dialog});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: dialog.icon != null
          ? Icon(dialog.icon, color: dialog.iconColor ?? AppColors.primary, size: 48)
          : null,
      title: Text(dialog.title),
      content: Text(dialog.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(dialog.buttonText ?? context.tr('ok')),
        ),
      ],
    );
  }
}
```

**Step 3: ListBottomSheet renderer**

```dart
// lib/core/navigation/widgets/list_bottom_sheet_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../models/app_bottom_sheet.dart';

class ListBottomSheetWidget<T> extends StatelessWidget {
  final ListBottomSheet<T> sheet;

  const ListBottomSheetWidget({super.key, required this.sheet});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (sheet.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                sheet.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ...sheet.options.map((option) => ListTile(
                leading: option.icon != null
                    ? Icon(option.icon, color: AppColors.textSecondary)
                    : null,
                title: Text(option.label),
                onTap: () => Navigator.of(context).pop(option.value),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
```

**Step 4: Verify all widgets**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/widgets/`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/core/navigation/widgets/
git commit -m "feat: add dialog and bottom sheet renderer widgets"
```

---

### Task 6: NavigationService Core

**Files:**
- Create: `lib/core/navigation/navigation_service.dart`

**Step 1: Implement NavigationService**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_event.dart';
import 'navigation_observer.dart';
import 'models/app_dialog.dart';
import 'models/app_bottom_sheet.dart';
import 'widgets/confirm_dialog_widget.dart';
import 'widgets/info_dialog_widget.dart';
import 'widgets/list_bottom_sheet_widget.dart';

class NavigationService {
  final GoRouter _router;
  final GlobalKey<NavigatorState> _rootNavigatorKey;
  final List<AppNavigationObserver> _observers;

  NavigationService({
    required GoRouter router,
    required GlobalKey<NavigatorState> rootNavigatorKey,
    List<AppNavigationObserver>? observers,
  })  : _router = router,
        _rootNavigatorKey = rootNavigatorKey,
        _observers = observers ?? [];

  // ─── Route Navigation ───

  void go(String name, {Map<String, String>? params, Object? extra}) {
    final event = NavigationEvent.go(name, pathParameters: params, extra: extra);
    _notifyNavigate(event);
    _router.goNamed(name, pathParameters: params ?? {}, extra: extra);
  }

  void push(String name, {Map<String, String>? params, Object? extra}) {
    final event = NavigationEvent.push(name, pathParameters: params, extra: extra);
    _notifyNavigate(event);
    _router.pushNamed(name, pathParameters: params ?? {}, extra: extra);
  }

  void pop<T>([T? result]) {
    final event = NavigationEvent.pop('current');
    _notifyPop(event);
    _router.pop(result);
  }

  bool canPop() => _router.canPop();

  // ─── Dialog ───

  Future<T?> showAppDialog<T>(AppDialog dialog) {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return Future.value(null);

    _notifyDialogOpen(dialog.name, _dialogParams(dialog));

    final Widget dialogWidget = switch (dialog) {
      ConfirmDialog d => ConfirmDialogWidget(dialog: d),
      InfoDialog d => InfoDialogWidget(dialog: d),
      CustomDialog d => d.builder(context),
    };

    return showDialog<T>(
      context: context,
      barrierDismissible: dialog.barrierDismissible,
      useRootNavigator: dialog.useRootNavigator,
      builder: (_) => dialogWidget,
    ).then((result) {
      _notifyDialogClose(dialog.name, result);
      return result;
    });
  }

  // ─── BottomSheet ───

  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return Future.value(null);

    _notifySheetOpen(sheet.name);

    final Widget sheetWidget = switch (sheet) {
      ListBottomSheet s => ListBottomSheetWidget(sheet: s),
      CustomBottomSheet s => s.builder(context),
    };

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: sheet.isDismissible,
      enableDrag: sheet.enableDrag,
      useRootNavigator: sheet.useRootNavigator,
      isScrollControlled: sheet.maxHeightFactor != null,
      constraints: sheet.maxHeightFactor != null
          ? BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * sheet.maxHeightFactor!,
            )
          : null,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => sheetWidget,
    ).then((result) {
      _notifySheetClose(sheet.name, result);
      return result;
    });
  }

  // ─── Overlay Close ───

  void closeOverlay<T>([T? result]) {
    final context = _rootNavigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  // ─── Deep Link ───

  void handleDeepLink(String uri) {
    for (final o in _observers) {
      o.onNavigate(NavigationEvent.go(uri));
    }
    _router.go(uri);
  }

  // ─── Observer Management ───

  void addObserver(AppNavigationObserver observer) => _observers.add(observer);
  void removeObserver(AppNavigationObserver observer) => _observers.remove(observer);

  // ─── Private Helpers ───

  void _notifyNavigate(NavigationEvent event) {
    for (final o in _observers) {
      o.onNavigate(event);
    }
  }

  void _notifyPop(NavigationEvent event) {
    for (final o in _observers) {
      o.onPop(event);
    }
  }

  void _notifyDialogOpen(String name, Map<String, dynamic>? params) {
    for (final o in _observers) {
      o.onDialogOpen(name, params: params);
    }
  }

  void _notifyDialogClose(String name, dynamic result) {
    for (final o in _observers) {
      o.onDialogClose(name, result: result);
    }
  }

  void _notifySheetOpen(String name) {
    for (final o in _observers) {
      o.onBottomSheetOpen(name);
    }
  }

  void _notifySheetClose(String name, dynamic result) {
    for (final o in _observers) {
      o.onBottomSheetClose(name, result: result);
    }
  }

  Map<String, dynamic>? _dialogParams(AppDialog dialog) {
    return switch (dialog) {
      ConfirmDialog d => {'type': 'ConfirmDialog', 'destructive': d.isDestructive},
      InfoDialog _ => {'type': 'InfoDialog'},
      CustomDialog _ => {'type': 'CustomDialog'},
    };
  }
}
```

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/navigation_service.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/navigation/navigation_service.dart
git commit -m "feat: implement NavigationService with route, dialog, sheet, and observer support"
```

---

### Task 7: Riverpod Provider & Router Key Integration

**Files:**
- Create: `lib/core/navigation/navigation_provider.dart`
- Modify: `lib/routing/app_router.dart`

**Step 1: Add rootNavigatorKey to GoRouter config**

In `lib/routing/app_router.dart`, add a top-level navigator key and pass it to GoRouter:

```dart
// Add at top of file, before routerProvider
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
```

Then in the `GoRouter` constructor, add `navigatorKey: rootNavigatorKey`:

```dart
return GoRouter(
  navigatorKey: rootNavigatorKey,  // ADD THIS
  initialLocation: '/',
  debugLogDiagnostics: true,
  ...
);
```

Also remove `debugLogDiagnostics: true` since LoggingObserver will handle this.

**Step 2: Create NavigationService provider**

```dart
// lib/core/navigation/navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routing/app_router.dart';
import 'navigation_service.dart';
import 'observers/logging_observer.dart';

final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.read(routerProvider);
  return NavigationService(
    router: router,
    rootNavigatorKey: rootNavigatorKey,
    observers: [LoggingObserver()],
  );
});
```

**Step 3: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/navigation/navigation_provider.dart lib/routing/app_router.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/core/navigation/navigation_provider.dart lib/routing/app_router.dart
git commit -m "feat: add navigationServiceProvider and rootNavigatorKey to GoRouter"
```

---

### Task 8: Barrel Export

**Files:**
- Create: `lib/core/navigation/navigation.dart`

**Step 1: Create barrel file for clean imports**

```dart
// lib/core/navigation/navigation.dart
export 'navigation_service.dart';
export 'navigation_event.dart';
export 'navigation_observer.dart';
export 'navigation_provider.dart';
export 'models/app_dialog.dart';
export 'models/app_bottom_sheet.dart';
```

**Step 2: Commit**

```bash
git add lib/core/navigation/navigation.dart
git commit -m "feat: add navigation barrel export"
```

---

### Task 9: Migrate SettingsScreen (Logout + Delete Account dialogs)

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`

**Step 1: Replace showDialog calls with NavigationService**

Replace the file content. Key changes:
- Remove `import 'package:go_router/go_router.dart'` (no longer needed)
- Add `import '../../../core/navigation/navigation.dart'`
- Replace logout dialog:
  ```dart
  // BEFORE:
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(...),
  );

  // AFTER:
  final nav = ref.read(navigationServiceProvider);
  final confirm = await nav.showAppDialog<bool>(
    ConfirmDialog(
      name: 'logout',
      title: context.tr('logout'),
      message: context.tr('logout_confirm'),
      confirmText: context.tr('logout'),
    ),
  );
  ```
- Replace delete account dialog:
  ```dart
  final nav = ref.read(navigationServiceProvider);
  final confirm = await nav.showAppDialog<bool>(
    ConfirmDialog(
      name: 'delete_account',
      title: context.tr('delete_account'),
      message: context.tr('delete_account_desc'),
      confirmText: context.tr('delete'),
      isDestructive: true,
    ),
  );
  ```

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/features/settings/screens/settings_screen.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/settings/screens/settings_screen.dart
git commit -m "refactor: migrate settings screen dialogs to NavigationService"
```

---

### Task 10: Migrate QuizScreen (Result dialog + navigation)

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: Replace navigation and dialog calls**

Key changes:
- Replace `import 'package:go_router/go_router.dart'` with `import '../../../core/navigation/navigation.dart'`
- Replace `context.pop()` close button:
  ```dart
  // BEFORE:
  onPressed: () => context.pop(),

  // AFTER:
  onPressed: () => ref.read(navigationServiceProvider).pop(),
  ```
- Replace `_showResult` method:
  ```dart
  // BEFORE: showDialog + Navigator.of(dialogContext).pop() + context.pop()

  // AFTER:
  Future<void> _showResult({required bool matched}) async {
    final nav = ref.read(navigationServiceProvider);
    await nav.showAppDialog(
      InfoDialog(
        name: 'quiz_result',
        title: matched ? context.tr('quiz_match') : context.tr('quiz_failed'),
        message: matched ? context.tr('quiz_match_desc') : context.tr('quiz_failed_desc'),
        icon: matched ? Icons.favorite : Icons.close,
        iconColor: matched ? AppColors.secondary : AppColors.error,
      ),
    );
    if (mounted) {
      nav.pop();
    }
  }
  ```

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/features/quiz/screens/quiz_screen.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/quiz/screens/quiz_screen.dart
git commit -m "refactor: migrate quiz screen to NavigationService"
```

---

### Task 11: Migrate QuestionsScreen (Add question dialog)

**Files:**
- Modify: `lib/features/profile/screens/questions_screen.dart`

**Step 1: Replace showDialog with CustomDialog via NavigationService**

The add question dialog uses `StatefulBuilder` for local state, so use `CustomDialog`:

```dart
// BEFORE: showDialog with inline AlertDialog + StatefulBuilder

// AFTER:
void _showAddDialog() {
  final nav = ref.read(navigationServiceProvider);
  nav.showAppDialog(
    CustomDialog(
      name: 'add_question',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tr('add_question')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: textCtrl, decoration: InputDecoration(labelText: context.tr('question'))),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: a1, decoration: InputDecoration(labelText: '${context.tr("correct_answer")} 1')),
                TextField(controller: a2, decoration: InputDecoration(labelText: '${context.tr("correct_answer")} 2')),
                TextField(controller: a3, decoration: InputDecoration(labelText: '${context.tr("correct_answer")} 3')),
                TextField(controller: a4, decoration: InputDecoration(labelText: '${context.tr("correct_answer")} 4')),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: correctAnswer,
                  items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Answer ${i + 1}'))),
                  onChanged: (v) => setDialogState(() => correctAnswer = v ?? 1),
                  decoration: InputDecoration(labelText: context.tr('correct_answer')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => nav.closeOverlay(),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () async {
                final questions = ref.read(questionProvider).valueOrNull ?? [];
                await ref.read(questionProvider.notifier).createQuestion({
                  'order_num': questions.length + 1,
                  'question_text': textCtrl.text,
                  'correct_answer': correctAnswer,
                  'answer_1': a1.text,
                  'answer_2': a2.text,
                  'answer_3': a3.text,
                  'answer_4': a4.text,
                });
                nav.closeOverlay();
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/features/profile/screens/questions_screen.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/profile/screens/questions_screen.dart
git commit -m "refactor: migrate questions screen dialog to NavigationService"
```

---

### Task 12: Migrate Route Navigation Screens (6 files)

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/chat/screens/matches_screen.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/auth/screens/forgot_password_screen.dart`
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`

**Step 1: Migrate each file**

For each file, the pattern is the same:
1. Replace `import 'package:go_router/go_router.dart'` with `import '../../../core/navigation/navigation.dart'`
2. Replace `context.goNamed(RouteNames.xxx, ...)` with `ref.read(navigationServiceProvider).go(RouteNames.xxx, ...)`
3. Replace `context.pushNamed(RouteNames.xxx)` with `ref.read(navigationServiceProvider).push(RouteNames.xxx)`
4. Replace `context.pop()` with `ref.read(navigationServiceProvider).pop()`

**Important notes per file:**

**discover_screen.dart** — Already ConsumerStatefulWidget, has `ref`:
```dart
// Line 72, 109: context.goNamed(RouteNames.quiz, pathParameters: {...})
// BECOMES:
ref.read(navigationServiceProvider).go(RouteNames.quiz, params: {'targetId': card.userId});
```

**matches_screen.dart** — ConsumerStatefulWidget. But `_MatchCard` is StatelessWidget without `ref`. Two options:
- Pass `NavigationService` as parameter to `_MatchCard`
- Or keep `_MatchCard` using context.goNamed and convert it to ConsumerWidget

Best approach: Convert `_MatchCard` to accept a `VoidCallback onTap` parameter instead of navigating itself:
```dart
// In _MatchesScreenState build:
_MatchCard(
  match: m,
  onTap: () => ref.read(navigationServiceProvider).go(
    RouteNames.chat,
    params: {'matchId': m.matchId},
  ),
)

// In _MatchCard: just use the callback
onTap: onTap,  // instead of context.goNamed(...)
```

Same for the horizontal list GestureDetector — it's already in ConsumerState, direct `ref` access.

**profile_screen.dart** — ConsumerStatefulWidget. `_MenuItem` takes `VoidCallback onTap`, so the caller already controls navigation. Just change the callers:
```dart
_MenuItem(icon: Icons.edit, title: context.tr('edit_profile'),
    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile)),
// Same for questions, diamonds, passport
```
Settings icon:
```dart
onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.settings),
```

**login_screen.dart** — ConsumerStatefulWidget:
```dart
// Line 131: context.pushNamed(RouteNames.forgotPassword)
ref.read(navigationServiceProvider).push(RouteNames.forgotPassword);
// Line 149: context.pushNamed(RouteNames.register)
ref.read(navigationServiceProvider).push(RouteNames.register);
```

**forgot_password_screen.dart** — ConsumerStatefulWidget:
```dart
// Line 42: context.pop()
ref.read(navigationServiceProvider).pop();
```

**onboarding_screen.dart** — This is a plain StatefulWidget (not Consumer). Need to convert to ConsumerStatefulWidget:
```dart
// Change: class OnboardingScreen extends StatefulWidget
// To:     class OnboardingScreen extends ConsumerStatefulWidget
// Change: State<OnboardingScreen>
// To:     ConsumerState<OnboardingScreen>

// Then replace:
// context.goNamed(RouteNames.discover)
ref.read(navigationServiceProvider).go(RouteNames.discover);
```

**register_screen.dart** — ConsumerStatefulWidget:
```dart
// Line 232: context.goNamed(RouteNames.login)
ref.read(navigationServiceProvider).go(RouteNames.login);
```
Note: Also need to add `import '../../../core/navigation/navigation.dart'` and can remove `import 'package:go_router/go_router.dart'`.

**Step 2: Verify all files**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/features/`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart \
        lib/features/chat/screens/matches_screen.dart \
        lib/features/profile/screens/profile_screen.dart \
        lib/features/auth/screens/login_screen.dart \
        lib/features/auth/screens/register_screen.dart \
        lib/features/auth/screens/forgot_password_screen.dart \
        lib/features/onboarding/screens/onboarding_screen.dart
git commit -m "refactor: migrate all screen navigation to NavigationService"
```

---

### Task 13: Root Navigator for Quiz Route

**Files:**
- Modify: `lib/routing/app_routes.dart`

**Step 1: Move quiz route to root navigator**

Move the quiz GoRoute from inside discover branch to top-level with `parentNavigatorKey`:

```dart
// BEFORE (inside StatefulShellBranch discover):
// GoRoute(path: 'quiz/:targetId', name: RouteNames.quiz, ...)

// AFTER (top-level route, after StatefulShellRoute):
GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  path: '/quiz/:targetId',
  name: RouteNames.quiz,
  builder: (context, state) => QuizScreen(
    targetId: state.pathParameters['targetId']!,
  ),
),
```

Note: Path changes from relative `quiz/:targetId` to absolute `/quiz/:targetId` since it's now top-level.

**Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/routing/`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/routing/app_routes.dart
git commit -m "refactor: move quiz route to root navigator (full-screen, no bottom nav)"
```

---

### Task 14: Full App Verification

**Step 1: Run full analysis**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze`
Expected: No issues found

**Step 2: Verify no remaining old patterns**

Search codebase for any remaining `context.goNamed`, `context.pushNamed`, `context.pop()`, `Navigator.pop` usage in screen files (not in navigation widgets which correctly use it).

Run: `grep -rn "context\.goNamed\|context\.pushNamed\|context\.pop\|Navigator\.pop\|Navigator\.of" lib/features/`
Expected: No results (all migrated)

Note: `Navigator.of(context).pop()` in `lib/core/navigation/widgets/` is CORRECT — those are dialog widget renderers where context is the dialog's own context.

**Step 3: Verify GoRouter import is removed from screen files**

Run: `grep -rn "import.*go_router" lib/features/`
Expected: No results

**Step 4: Commit final cleanup if needed**

---

### Task 15: Update CLAUDE.md with Navigation Convention

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add navigation convention to Conventions section**

Add under `## Conventions`:
```
- Navigation: Always use NavigationService via `ref.read(navigationServiceProvider)`, never direct GoRouter/Navigator calls in screens
- Dialogs: Use `ConfirmDialog`, `InfoDialog`, or `CustomDialog` via `NavigationService.showAppDialog()`
- BottomSheets: Use `ListBottomSheet` or `CustomBottomSheet` via `NavigationService.showAppBottomSheet()`
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add navigation conventions to CLAUDE.md"
```
