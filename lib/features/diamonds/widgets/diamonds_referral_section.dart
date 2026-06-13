import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiamondsReferralSection extends ConsumerStatefulWidget {
  final String? prefillCode;

  const DiamondsReferralSection({super.key, this.prefillCode});

  @override
  ConsumerState<DiamondsReferralSection> createState() =>
      _DiamondsReferralSectionState();
}

class _DiamondsReferralSectionState
    extends ConsumerState<DiamondsReferralSection> {
  bool _applyingCode = false;
  String? _applyError;
  String? _applySuccessName;

  Future<void> _onApplyCode(String code) async {
    setState(() {
      _applyingCode = true;
      _applyError = null;
      _applySuccessName = null;
    });

    final result = await ref.read(referralProvider.notifier).applyCode(code);

    if (!mounted) return;

    result.when(
      success: (referrerName) {
        setState(() {
          _applyingCode = false;
          _applySuccessName = referrerName;
        });
      },
      failure: (f) {
        final errorCode = switch (f) {
          ServerFailure(:final code) => code,
          _ => 'UNKNOWN',
        };
        setState(() {
          _applyingCode = false;
          _applyError = context.tr(
            errorCode == 'SELF_REFERRAL'
                ? 'referral_self_error'
                : errorCode == 'ALREADY_REFERRED'
                    ? 'referral_already_error'
                    : 'referral_code_invalid',
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(referralProvider);

    return referralAsync.when(
      loading: () => const Center(child: AppLoadingWidget.small()),
      error: (_, __) => const SizedBox.shrink(),
      data: (referralState) => ReferralInviteCard(
        code: referralState.code,
        stats: referralState.stats,
        referredBy: _applySuccessName ?? referralState.referredBy,
        referralStatus: _applySuccessName != null
            ? 'pending'
            : referralState.referralStatus,
        onApplyCode: referralState.hasAppliedCode || _applySuccessName != null
            ? null
            : _onApplyCode,
        applyingCode: _applyingCode,
        applyError: _applyError,
        applySuccessName: _applySuccessName,
        initialCode: widget.prefillCode,
        onShare: () {
          if (referralState.code != null) {
            final code = referralState.code!;
            final reward =
                ref.read(economyConfigProvider).rewards.referralPurple;
            final message = context
                .tr('referral_share_message')
                .replaceAll('@reward', '$reward')
                .replaceAll('@code', code);
            ref.read(shareManagerProvider).share(message);
          }
        },
      ),
    );
  }
}
