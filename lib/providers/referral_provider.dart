import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class ReferralState extends Equatable {
  final String? code;
  final ReferralStats? stats;
  final List<ReferralItem> history;

  const ReferralState({
    this.code,
    this.stats,
    this.history = const [],
  });

  ReferralState copyWith({
    String? code,
    ReferralStats? stats,
    List<ReferralItem>? history,
  }) {
    return ReferralState(
      code: code ?? this.code,
      stats: stats ?? this.stats,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [code, stats, history];
}

class ReferralNotifier extends AsyncNotifier<ReferralState> {
  @override
  Future<ReferralState> build() async {
    return const ReferralState();
  }

  Future<void> fetchAll() async {
    state = const AsyncLoading();

    final repo = ref.read(referralRepositoryProvider);
    final codeResult = await repo.getMyCode();
    final statsResult = await repo.getStats();
    final historyResult = await repo.getHistory();

    String? code;
    ReferralStats? stats;
    List<ReferralItem> history = [];

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

    state = AsyncData(ReferralState(
      code: code,
      stats: stats,
      history: history,
    ));
  }

  Future<Result<ValidateCodeResponse>> validateCode(String code) async {
    return ref.read(referralRepositoryProvider).validateCode(code);
  }
}

final referralProvider =
    AsyncNotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
