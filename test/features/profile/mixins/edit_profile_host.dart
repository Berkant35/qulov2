import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_photos_mixin.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_screen_mixin.dart';
import 'package:qulo_v2/features/profile/screens/edit_profile_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Profil düzenleme async-gap testlerinin ortak host'u: gerçek ekran yerine aynı mixin
/// zinciri (EditProfileScreenMixin + EditProfilePhotosMixin), build = SizedBox. Ekran
/// `UncontrolledProviderScope` korunarak kapatılır/açılır — uygulama kapsamı yaşar.
class HostEdit extends EditProfileScreen {
  const HostEdit({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => HostEditState();
}

class HostEditState extends ConsumerState<EditProfileScreen>
    with EditProfileScreenMixin, EditProfilePhotosMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class FakeCropPicker implements ImagePickerManager {
  @override
  Future<PickedImage?> pickAndCrop(
    BuildContext context,
    ImageSource source, {
    double maxWidth = 0,
    int imageQuality = 0,
  }) async =>
      PickedImage(bytes: Uint8List(4), mimeType: 'image/jpeg', fileName: 'p.jpg');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeCropPicker.${invocation.memberName}');
}

class EditHarness {
  EditHarness._(this.repo, this.nav, this.container);

  final FakeUserRepository repo;
  final FakeNavigationService nav;
  final ProviderContainer container;
  late HostEditState state;

  /// Kullanıcı yüklü (fetchMe), ekran henüz açık değil.
  static Future<EditHarness> create({UserModel? user, List<Override> overrides = const []}) async {
    final repo = FakeUserRepository(
      user ?? UserModel(id: 'u1', email: 'u1@qulo.test', photos: const ['a.jpg', 'b.jpg']),
    );
    final nav = FakeNavigationService();
    final container = ProviderContainer(overrides: [
      userRepositoryProvider.overrideWithValue(repo),
      navigationServiceProvider.overrideWithValue(nav),
      imagePickerManagerProvider.overrideWithValue(FakeCropPicker()),
      ...overrides,
    ]);
    addTearDown(container.dispose);
    await container.read(userProvider.notifier).fetchMe();
    return EditHarness._(repo, nav, container);
  }

  EditProfileState get edit => container.read(editProfileProvider);
  List<String?> get photos => edit.photos;

  Widget _app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: home,
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(_app(const HostEdit()));
    await tester.pump();
    state = tester.state<HostEditState>(find.byType(HostEdit));
  }

  /// Düzenleme ekranı kapanır; uygulama kapsamı (container) yaşamaya devam eder.
  Future<void> close(WidgetTester tester) => tester.pumpWidget(_app(const SizedBox()));
}
