---
name: gen-screen
description: Generate a new Flutter screen with NavigationService, AppScaffold, and route registration
disable-model-invocation: true
---

# Generate Screen

Creates a new Flutter screen with all boilerplate wired up.

## Arguments

- `<feature>` — Feature name (e.g., `profile`, `auth`, `discover`)
- `<screen-name>` — Screen name in kebab-case (e.g., `edit-profile`)

## Steps

1. Create screen file at `lib/features/<feature>/screens/<screen_name>_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../routing/route_names.dart';

class <ScreenName>Screen extends ConsumerStatefulWidget {
  const <ScreenName>Screen({super.key});

  @override
  ConsumerState<<ScreenName>Screen> createState() => _<ScreenName>ScreenState();
}

class _<ScreenName>ScreenState extends ConsumerState<<ScreenName>Screen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.tr('<screen_key>'),
      body: const Center(
        child: Text('TODO'),
      ),
    );
  }
}
```

2. Add route name to `lib/routing/route_names.dart`
3. Add GoRoute to `lib/routing/app_routes.dart` under the appropriate branch
4. Add import to `lib/routing/app_router.dart`
5. Run `dart analyze lib/` to verify

## Conventions

- Screen must use `ConsumerStatefulWidget`
- Navigation via `ref.read(navigationServiceProvider)` only
- All text via `context.tr()` for i18n
- Colors from `AppColors`, spacing from `AppSpacing`
- Wrap body with `AppScaffold`
