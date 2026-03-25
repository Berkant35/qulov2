import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/profile/screens/profile_preview_screen.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin ProfilePreviewScreenMixin on ConsumerState<ProfilePreviewScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profilePreviewOpened,
      params: {
        AnalyticsEvents.paramSource: widget.source,
      },
    );
  }

  void disposeMixin() {}

  void onEditProfile() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.profilePreviewEditTapped);
    final nav = ref.read(navigationServiceProvider);
    nav.pop();
    if (widget.source != 'edit_screen') {
      nav.push(RouteNames.editProfile);
    }
  }

  void onClose() {
    ref.read(navigationServiceProvider).pop();
  }

  void onPhotoChanged(int index, int total) {
    // No analytics needed for own profile photo nav
  }
}
