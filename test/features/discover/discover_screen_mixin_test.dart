import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../helpers/fake_location_manager.dart';

/// Crashlytics 2.0.12 `discover_screen_mixin.dart:127` — "Cannot use ref after
/// the widget was disposed": konum alinirken (izin diyalogu + GPS) ekran
/// kapaniyor (setup-gate redirect / sekme), await sonrasi `ref.read` patliyor.
/// riverpod 2.6.1 bunu assert degil StateError olarak atar — release'de de.
class _HostScreen extends DiscoverScreen {
  const _HostScreen();

  @override
  ConsumerState<DiscoverScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<DiscoverScreen> with DiscoverScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('konum beklenirken ekran kapanırsa ref kullanılmaz', (tester) async {
    final location = FakeLocationManager();
    final container = ProviderContainer(
      overrides: [locationManagerProvider.overrideWithValue(location)],
    );
    addTearDown(container.dispose);

    Widget scoped(Widget child) =>
        UncontrolledProviderScope(container: container, child: MaterialApp(home: child));

    await tester.pumpWidget(scoped(const _HostScreen()));
    final state = tester.state<_HostState>(find.byType(_HostScreen));

    final pending = state.initLocationAndDiscover();
    await tester.pump();

    await tester.pumpWidget(scoped(const SizedBox.shrink()));
    location.position.completeError(Exception('gps'));

    await expectLater(pending, completes);
  });
}
