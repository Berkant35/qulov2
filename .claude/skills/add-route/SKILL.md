---
name: add-route
description: Add a new GoRouter route with NavigationService integration
disable-model-invocation: true
---

# Add Route

Registers a new route in GoRouter with proper NavigationService setup.

## Arguments

- `<route-name>` — Route name constant (e.g., `editProfile`)
- `<path>` — URL path (e.g., `/profile/edit` or `edit` for nested)
- `<parent>` — (optional) Parent route to nest under (e.g., `profile`). If omitted, added as top-level.
- `--root` — (optional) Use root navigator (full-screen, no bottom nav)

## Steps

1. Add route name constant to `lib/routing/route_names.dart`:
   ```dart
   static const <routeName> = '<route-name-kebab>';
   ```

2. Add GoRoute to `lib/routing/app_routes.dart`:
   - If `--root` flag: add `parentNavigatorKey: rootNavigatorKey` and place as top-level route
   - If `<parent>` specified: nest inside parent's `routes: []`
   - Otherwise: add as top-level route

3. Add screen import to `lib/routing/app_router.dart`

4. Run `dart analyze lib/` to verify no issues

## Rules

- Route path must be kebab-case
- Route name constant must be camelCase
- Screen class must already exist (use `/gen-screen` first if needed)
- Always use `builder:` not `pageBuilder:` unless custom transitions needed
