import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/share_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/data/repositories/referral_repository.dart';
import 'package:qulo_v2/features/discover/widgets/discover_invite_hint.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

/// Bu dosya bir kor noktayi kapatmak icin var.
///
/// Davet girisi ilk yazildiginda karar fonksiyonunun 6 testi vardi ve hepsi
/// yesildi — ama `referralProvider` kendi kendini doldurmadigi ve onu ceken tek
/// yer Elmaslar ekrani oldugu icin giris, Elmaslar'a hic girmemis kullanicida
/// (yani tam olarak hedef kitlede) hic cizilmiyordu. Karari test etmek yetmedi;
/// verinin akisa geldigini de test etmek gerekiyordu.
void main() {
  testWidgets('kod yoksa cekilir ve geldiginde giris cizilir', (tester) async {
    final repo = _FakeReferralRepository(code: 'ABC123', remaining: 10);
    final share = _RecordingShareManager();
    await _pump(tester, repo: repo, share: share);

    expect(repo.codeCalls, 1, reason: 'giris kendi verisini istemeli');
    // `TextButton.icon` private bir alt sinif dondurur, `find.byType` onu
    // eslemez — ikonla ve metinle araniyor (projedeki mevcut testlerin yolu).
    expect(find.byIcon(Icons.person_add_alt), findsOneWidget);

    final label = tester
        .element(find.byType(DiscoverInviteHint))
        .tr('discover_invite_friend')
        .replaceAll('@reward', '25');
    expect(find.text(label), findsOneWidget);
    expect(
      find.textContaining('@reward'),
      findsNothing,
      reason: 'ham yer tutucu ekranda kalmamali',
    );
  });

  testWidgets('paylas: davet metni kod ve odulle gonderilir', (tester) async {
    final share = _RecordingShareManager();
    await _pump(
      tester,
      repo: _FakeReferralRepository(code: 'ABC123', remaining: 10),
      share: share,
    );

    await tester.tap(find.byIcon(Icons.person_add_alt));
    await tester.pump();

    expect(share.shared, hasLength(1));
    expect(share.shared.single, contains('ABC123'));
    expect(share.shared.single, contains('quloapp.com/invite/ABC123'));
    expect(share.shared.single, isNot(contains('@code')));
    expect(share.shared.single, isNot(contains('@reward')));
  });

  testWidgets('kota dolduysa giris cizilmez', (tester) async {
    await _pump(
      tester,
      repo: _FakeReferralRepository(code: 'ABC123', remaining: 0),
      share: _RecordingShareManager(),
    );
    expect(find.byIcon(Icons.person_add_alt), findsNothing);
  });

  testWidgets('kod alinamazsa giris cizilmez — bos alan birakir', (tester) async {
    final repo = _FakeReferralRepository(code: null, remaining: 10);
    await _pump(tester, repo: repo, share: _RecordingShareManager());

    expect(repo.codeCalls, 1);
    expect(find.byIcon(Icons.person_add_alt), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeReferralRepository repo,
  required _RecordingShareManager share,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _AuthenticatedNotifier()),
      referralRepositoryProvider.overrideWithValue(repo),
      shareManagerProvider.overrideWithValue(share),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: const Scaffold(body: DiscoverInviteHint()),
    ),
  ));
  // initState -> Future.microtask -> fetchAll (4 asenkron repo cagrisi) -> state
  await tester.pumpAndSettle();
}

class _AuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FakeReferralRepository implements ReferralRepository {
  _FakeReferralRepository({required this.code, required this.remaining});

  final String? code;
  final int remaining;
  int codeCalls = 0;

  @override
  Future<Result<String>> getMyCode() async {
    codeCalls++;
    final value = code;
    if (value == null) return const Failure(NetworkFailure());
    return Success(value);
  }

  @override
  Future<Result<ReferralStats>> getStats() async => Success(
        ReferralStats(total: 0, pending: 0, completed: 0, remaining: remaining),
      );

  @override
  Future<Result<List<ReferralItem>>> getHistory() async => const Success([]);

  @override
  Future<Result<MyReferrerResponse>> getMyReferrer() async =>
      const Success(MyReferrerResponse());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeReferralRepository.${invocation.memberName}');
}

class _RecordingShareManager implements ShareManager {
  final shared = <String>[];

  @override
  Future<void> share(String text, {String? subject}) async => shared.add(text);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingShareManager.${invocation.memberName}');
}
