import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class ReferralState extends Equatable {
  final String? code;
  final ReferralStats? stats;
  final List<ReferralItem> history;
  final String? referredBy;
  final String? referralStatus;

  const ReferralState({
    this.code,
    this.stats,
    this.history = const [],
    this.referredBy,
    this.referralStatus,
  });

  bool get hasAppliedCode => referredBy != null;

  ReferralState copyWith({
    String? code,
    ReferralStats? stats,
    List<ReferralItem>? history,
    String? referredBy,
    String? referralStatus,
  }) {
    return ReferralState(
      code: code ?? this.code,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      referredBy: referredBy ?? this.referredBy,
      referralStatus: referralStatus ?? this.referralStatus,
    );
  }

  @override
  List<Object?> get props => [code, stats, history, referredBy, referralStatus];
}

class ReferralNotifier extends AsyncNotifier<ReferralState> {
  /// Veriyi kendisi yukler — cagiranin `fetchAll()` demesini beklemez.
  ///
  /// Onceki hali bos bir `ReferralState()` donuyordu ve onu dolduran tek yer
  /// Elmaslar ekraninin `initMixin`'iydi. Sonuc: baska bir ekran davet kodunu
  /// okumak istediginde `code` her zaman `null` oluyordu. Ustelik cagiran
  /// `fetchAll()` derse yaris cikiyordu — `build()`'in bos sonucu sonra
  /// cozulup dolu state'in uzerine yaziyordu.
  ///
  /// `subscriptionProvider` ile ayni desen: kimliksizken aga hic cikilmaz
  /// (token'siz istek → 401 → Crashlytics gurultusu), logout'ta
  /// `auth_provider` bu provider'i zaten invalidate ediyor.
  @override
  Future<ReferralState> build() async {
    final authStatus = ref.watch(authProvider.select((s) => s.status));
    if (authStatus != AuthStatus.authenticated) return const ReferralState();
    return _load();
  }

  /// Ekrandan elle yenileme (Elmaslar ekrani kod uygulandiktan sonra kullanir).
  Future<void> fetchAll() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<ReferralState> _load() async {
    final repo = ref.read(referralRepositoryProvider);
    final codeResult = await repo.getMyCode();
    final statsResult = await repo.getStats();
    final historyResult = await repo.getHistory();
    final referrerResult = await repo.getMyReferrer();

    String? code;
    ReferralStats? stats;
    List<ReferralItem> history = [];
    String? referredBy;
    String? referralStatus;

    codeResult.when(
      success: (data) => code = data,
      failure: (_) {},
    );
    statsResult.when(
      success: (data) => stats = data,
      failure: (_) {},
    );
    historyResult.when(
      success: (data) => history = data,
      failure: (_) {},
    );
    referrerResult.when(
      success: (data) {
        referredBy = data.referrerName;
        referralStatus = data.status;
      },
      failure: (_) {},
    );

    return ReferralState(
      code: code,
      stats: stats,
      history: history,
      referredBy: referredBy,
      referralStatus: referralStatus,
    );
  }

  Future<Result<ValidateCodeResponse>> validateCode(String code) async {
    return ref.read(referralRepositoryProvider).validateCode(code);
  }

  Future<Result<String>> applyCode(String code) async {
    final result = await ref.read(referralRepositoryProvider).applyCode(code);
    result.when(
      success: (referrerName) {
        final current = state.valueOrNull ?? const ReferralState();
        state = AsyncData(current.copyWith(
          referredBy: referrerName,
          referralStatus: 'pending',
        ));
      },
      failure: (_) {},
    );
    return result;
  }
}

final referralProvider =
    AsyncNotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
