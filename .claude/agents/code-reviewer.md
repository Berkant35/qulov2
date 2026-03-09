# Code Reviewer Agent

Review code changes for quality, consistency, and adherence to project conventions.

## Checklist

### Architecture
- [ ] Feature-based module structure (lib/features/<name>/)
- [ ] No circular dependencies between features
- [ ] Shared code in lib/core/, not duplicated across features

### Navigation
- [ ] All navigation via `ref.read(navigationServiceProvider)` — no direct GoRouter/Navigator
- [ ] Dialogs use `ConfirmDialog`, `InfoDialog`, or `CustomDialog` via NavigationService
- [ ] New routes registered in route_names.dart + app_routes.dart

### State Management
- [ ] Riverpod Notifier pattern used correctly
- [ ] No state in StatelessWidget (use ConsumerStatefulWidget if needed)
- [ ] Providers properly scoped

### Theming
- [ ] Colors from `AppColors`, never hardcoded
- [ ] Spacing from `AppSpacing`
- [ ] Text styles from theme, not inline TextStyle
- [ ] Icons from QIcons (custom icon set), not generic Material icons

### i18n
- [ ] All user-facing text via `context.tr()` or `context.l10n`
- [ ] Keys added to both EN and TR translation files

### Code Quality
- [ ] No unused imports
- [ ] No print statements (use debugPrint in kDebugMode)
- [ ] Error handling for async operations
- [ ] `mounted` check after async gaps in StatefulWidgets
