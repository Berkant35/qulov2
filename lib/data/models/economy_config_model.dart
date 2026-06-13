import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// EconomyConfigResponse — top-level API envelope
// ---------------------------------------------------------------------------

class EconomyConfigResponse {
  final int version;
  final EconomyConfig config;

  const EconomyConfigResponse({
    required this.version,
    required this.config,
  });

  factory EconomyConfigResponse.fromJson(Map<String, dynamic> json) {
    return EconomyConfigResponse(
      version: json['version'] as int? ?? 1,
      config: json['config'] != null
          ? EconomyConfig.fromJson(json['config'] as Map<String, dynamic>)
          : EconomyConfig.fallback,
    );
  }
}

// ---------------------------------------------------------------------------
// EconomyConfig — main config object
// ---------------------------------------------------------------------------

class EconomyConfig extends Equatable {
  final EconomyCoreConfig core;
  final Map<String, TierLimits> subscriptionLimits;
  final RewardsConfig rewards;
  final TimingConfig timing;
  final PowerCostsConfig powerCosts;

  const EconomyConfig({
    required this.core,
    required this.subscriptionLimits,
    required this.rewards,
    required this.timing,
    required this.powerCosts,
  });

  /// Returns limits for the given subscription plan.
  /// Falls back to 'free' if the plan is null, unknown, or missing.
  TierLimits limitsFor(String? plan) {
    if (plan == null) return subscriptionLimits['free'] ?? TierLimits.free;
    return subscriptionLimits[plan] ?? subscriptionLimits['free'] ?? TierLimits.free;
  }

  // -------------------------------------------------------------------------
  // Fallback — exact v1 seed values
  // -------------------------------------------------------------------------

  static const EconomyConfig fallback = EconomyConfig(
    core: EconomyCoreConfig(
      boostCostGreen: 30,
      boostDurationMinutes: 30,
      greenDiamondRewardRatio: 0.30,
      greenToPurpleRatio: 3,
      questionCountMultipliers: {
        2: 0.5,
        3: 0.75,
        4: 1.0,
        5: 1.25,
        6: 1.5,
      },
    ),
    subscriptionLimits: {
      'free': TierLimits(
        dailyDiscovers: 50,
        maxQuestions: 4,
        dailyUndos: 0,
        monthlyPurpleBonus: 0,
        chatQuestionDaily: 2,
        chatQuestionUnmatchRisk: 1,
        passportMode: false,
        hasAds: true,
      ),
      'plus': TierLimits(
        dailyDiscovers: 999999,
        maxQuestions: 6,
        dailyUndos: 3,
        monthlyPurpleBonus: 500,
        chatQuestionDaily: 5,
        chatQuestionUnmatchRisk: 2,
        passportMode: false,
        hasAds: false,
      ),
      'premium': TierLimits(
        dailyDiscovers: 999999,
        maxQuestions: 10,
        dailyUndos: 999999,
        monthlyPurpleBonus: 1500,
        chatQuestionDaily: 999999,
        chatQuestionUnmatchRisk: 999999,
        passportMode: true,
        hasAds: false,
      ),
    },
    rewards: RewardsConfig(
      milestones: {
        25: 5,
        50: 15,
        75: 30,
        100: 50,
      },
      referralPurple: 25,
      maxCompletedReferrals: 10,
    ),
    timing: TimingConfig(
      questionTimeSeconds: 30,
      timeExtendSeconds: 15,
      timePresets: [15, 30, 60, 90],
    ),
    powerCosts: PowerCostsConfig.fallback,
  );

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  factory EconomyConfig.fromJson(Map<String, dynamic> json) {
    final rawLimits = json['subscriptionLimits'] as Map<String, dynamic>?;
    final parsedLimits = <String, TierLimits>{};
    if (rawLimits != null) {
      for (final entry in rawLimits.entries) {
        parsedLimits[entry.key] =
            TierLimits.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    return EconomyConfig(
      core: json['core'] != null
          ? EconomyCoreConfig.fromJson(json['core'] as Map<String, dynamic>)
          : fallback.core,
      subscriptionLimits:
          parsedLimits.isNotEmpty ? parsedLimits : fallback.subscriptionLimits,
      rewards: json['rewards'] != null
          ? RewardsConfig.fromJson(json['rewards'] as Map<String, dynamic>)
          : fallback.rewards,
      timing: json['timing'] != null
          ? TimingConfig.fromJson(json['timing'] as Map<String, dynamic>)
          : fallback.timing,
      powerCosts: json['powerCosts'] != null
          ? PowerCostsConfig.fromJson(json['powerCosts'] as Map<String, dynamic>)
          : PowerCostsConfig.fallback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'core': core.toJson(),
      'subscriptionLimits': subscriptionLimits.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'rewards': rewards.toJson(),
      'timing': timing.toJson(),
      'powerCosts': powerCosts.toJson(),
    };
  }

  @override
  List<Object?> get props => [core, subscriptionLimits, rewards, timing, powerCosts];
}

// ---------------------------------------------------------------------------
// EconomyCoreConfig
// ---------------------------------------------------------------------------

class EconomyCoreConfig extends Equatable {
  final int boostCostGreen;
  final int boostDurationMinutes;
  final double greenDiamondRewardRatio;
  final int greenToPurpleRatio;
  final int baseAnswerReward;
  final Map<int, double> questionCountMultipliers;

  const EconomyCoreConfig({
    required this.boostCostGreen,
    required this.boostDurationMinutes,
    required this.greenDiamondRewardRatio,
    required this.greenToPurpleRatio,
    this.baseAnswerReward = 10,
    required this.questionCountMultipliers,
  });

  factory EconomyCoreConfig.fromJson(Map<String, dynamic> json) {
    final rawMultipliers =
        json['questionCountMultipliers'] as Map<String, dynamic>?;
    final parsedMultipliers = <int, double>{};
    if (rawMultipliers != null) {
      for (final entry in rawMultipliers.entries) {
        final key = int.tryParse(entry.key);
        if (key != null) {
          parsedMultipliers[key] = (entry.value as num).toDouble();
        }
      }
    }

    return EconomyCoreConfig(
      boostCostGreen: json['boostCostGreen'] as int? ?? 30,
      boostDurationMinutes: json['boostDurationMinutes'] as int? ?? 30,
      greenDiamondRewardRatio:
          (json['greenDiamondRewardRatio'] as num?)?.toDouble() ?? 0.30,
      greenToPurpleRatio: json['greenToPurpleRatio'] as int? ?? 3,
      baseAnswerReward: json['baseAnswerReward'] as int? ?? 10,
      questionCountMultipliers: parsedMultipliers.isNotEmpty
          ? parsedMultipliers
          : const {2: 0.5, 3: 0.75, 4: 1.0, 5: 1.25, 6: 1.5},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boostCostGreen': boostCostGreen,
      'boostDurationMinutes': boostDurationMinutes,
      'greenDiamondRewardRatio': greenDiamondRewardRatio,
      'greenToPurpleRatio': greenToPurpleRatio,
      'baseAnswerReward': baseAnswerReward,
      'questionCountMultipliers': questionCountMultipliers
          .map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  @override
  List<Object?> get props => [
        boostCostGreen,
        boostDurationMinutes,
        greenDiamondRewardRatio,
        greenToPurpleRatio,
        baseAnswerReward,
        questionCountMultipliers,
      ];
}

// ---------------------------------------------------------------------------
// TierLimits
// ---------------------------------------------------------------------------

class TierLimits extends Equatable {
  final int dailyDiscovers;
  final int maxQuestions;
  final int dailyUndos;
  final int monthlyPurpleBonus;
  final int chatQuestionDaily;
  final int chatQuestionUnmatchRisk;
  final bool passportMode;
  final bool hasAds;

  const TierLimits({
    required this.dailyDiscovers,
    required this.maxQuestions,
    required this.dailyUndos,
    required this.monthlyPurpleBonus,
    required this.chatQuestionDaily,
    required this.chatQuestionUnmatchRisk,
    required this.passportMode,
    required this.hasAds,
  });

  static const TierLimits free = TierLimits(
    dailyDiscovers: 50,
    maxQuestions: 4,
    dailyUndos: 0,
    monthlyPurpleBonus: 0,
    chatQuestionDaily: 2,
    chatQuestionUnmatchRisk: 1,
    passportMode: false,
    hasAds: true,
  );

  factory TierLimits.fromJson(Map<String, dynamic> json) {
    return TierLimits(
      dailyDiscovers: json['dailyDiscovers'] as int? ?? 50,
      maxQuestions: json['maxQuestions'] as int? ?? 4,
      dailyUndos: json['dailyUndos'] as int? ?? 0,
      monthlyPurpleBonus: json['monthlyPurpleBonus'] as int? ?? 0,
      chatQuestionDaily: json['chatQuestionDaily'] as int? ?? 2,
      chatQuestionUnmatchRisk: json['chatQuestionUnmatchRisk'] as int? ?? 1,
      passportMode: json['passportMode'] as bool? ?? false,
      hasAds: json['hasAds'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyDiscovers': dailyDiscovers,
      'maxQuestions': maxQuestions,
      'dailyUndos': dailyUndos,
      'monthlyPurpleBonus': monthlyPurpleBonus,
      'chatQuestionDaily': chatQuestionDaily,
      'chatQuestionUnmatchRisk': chatQuestionUnmatchRisk,
      'passportMode': passportMode,
      'hasAds': hasAds,
    };
  }

  @override
  List<Object?> get props => [
        dailyDiscovers,
        maxQuestions,
        dailyUndos,
        monthlyPurpleBonus,
        chatQuestionDaily,
        chatQuestionUnmatchRisk,
        passportMode,
        hasAds,
      ];
}

// ---------------------------------------------------------------------------
// RewardsConfig
// ---------------------------------------------------------------------------

class RewardsConfig extends Equatable {
  /// Keys are answer counts (e.g. 25, 50, 75, 100),
  /// values are purple diamond rewards.
  final Map<int, int> milestones;
  final int referralPurple;
  final int maxCompletedReferrals;

  const RewardsConfig({
    required this.milestones,
    required this.referralPurple,
    required this.maxCompletedReferrals,
  });

  factory RewardsConfig.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as Map<String, dynamic>?;
    final parsedMilestones = <int, int>{};
    if (rawMilestones != null) {
      for (final entry in rawMilestones.entries) {
        final key = int.tryParse(entry.key);
        if (key != null) {
          parsedMilestones[key] = (entry.value as num).toInt();
        }
      }
    }

    return RewardsConfig(
      milestones: parsedMilestones.isNotEmpty
          ? parsedMilestones
          : const {25: 5, 50: 15, 75: 30, 100: 50},
      referralPurple: json['referralPurple'] as int? ?? 25,
      maxCompletedReferrals: json['maxCompletedReferrals'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'milestones':
          milestones.map((key, value) => MapEntry(key.toString(), value)),
      'referralPurple': referralPurple,
      'maxCompletedReferrals': maxCompletedReferrals,
    };
  }

  @override
  List<Object?> get props => [milestones, referralPurple, maxCompletedReferrals];
}

// ---------------------------------------------------------------------------
// TimingConfig
// ---------------------------------------------------------------------------

class TimingConfig extends Equatable {
  final int questionTimeSeconds;
  final int timeExtendSeconds;
  final List<int> timePresets;

  const TimingConfig({
    required this.questionTimeSeconds,
    required this.timeExtendSeconds,
    required this.timePresets,
  });

  factory TimingConfig.fromJson(Map<String, dynamic> json) {
    final rawPresets = json['timePresets'] as List<dynamic>?;
    final parsedPresets =
        rawPresets?.map((e) => (e as num).toInt()).toList() ?? [15, 30, 60, 90];

    return TimingConfig(
      questionTimeSeconds: json['questionTimeSeconds'] as int? ?? 30,
      timeExtendSeconds: json['timeExtendSeconds'] as int? ?? 15,
      timePresets: parsedPresets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionTimeSeconds': questionTimeSeconds,
      'timeExtendSeconds': timeExtendSeconds,
      'timePresets': timePresets,
    };
  }

  @override
  List<Object?> get props => [questionTimeSeconds, timeExtendSeconds, timePresets];
}

// ---------------------------------------------------------------------------
// PowerCostConfig — per-power pricing
// ---------------------------------------------------------------------------

class PowerCostConfig extends Equatable {
  final int greenCost;
  final int purpleCost;

  const PowerCostConfig({
    required this.greenCost,
    required this.purpleCost,
  });

  factory PowerCostConfig.fromJson(Map<String, dynamic> json) {
    return PowerCostConfig(
      greenCost: json['greenCost'] as int? ?? 0,
      purpleCost: json['purpleCost'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'greenCost': greenCost,
    'purpleCost': purpleCost,
  };

  @override
  List<Object?> get props => [greenCost, purpleCost];
}

// ---------------------------------------------------------------------------
// PowerCostsConfig — all power prices
// ---------------------------------------------------------------------------

class PowerCostsConfig extends Equatable {
  final PowerCostConfig oracle;
  final PowerCostConfig half;
  final PowerCostConfig skip;
  final PowerCostConfig skipAll;
  final PowerCostConfig timeExtend;
  final PowerCostConfig hint;
  final PowerCostConfig powerBlock;
  final PowerCostConfig powerUnblock;

  const PowerCostsConfig({
    required this.oracle,
    required this.half,
    required this.skip,
    required this.skipAll,
    required this.timeExtend,
    required this.hint,
    required this.powerBlock,
    required this.powerUnblock,
  });

  /// Get cost for a power by its API name (e.g. 'ORACLE', 'HALF')
  PowerCostConfig? forPower(String apiName) => switch (apiName) {
    'ORACLE' => oracle,
    'HALF' => half,
    'SKIP' => skip,
    'SKIP_ALL' => skipAll,
    'TIME_EXTEND' => timeExtend,
    'HINT' => hint,
    'POWER_BLOCK' => powerBlock,
    'POWER_UNBLOCK' => powerUnblock,
    _ => null,
  };

  static const PowerCostsConfig fallback = PowerCostsConfig(
    oracle: PowerCostConfig(greenCost: 15, purpleCost: 5),
    half: PowerCostConfig(greenCost: 30, purpleCost: 10),
    skip: PowerCostConfig(greenCost: 60, purpleCost: 20),
    skipAll: PowerCostConfig(greenCost: 180, purpleCost: 60),
    timeExtend: PowerCostConfig(greenCost: 15, purpleCost: 5),
    hint: PowerCostConfig(greenCost: 24, purpleCost: 8),
    powerBlock: PowerCostConfig(greenCost: 45, purpleCost: 15),
    powerUnblock: PowerCostConfig(greenCost: 45, purpleCost: 15),
  );

  factory PowerCostsConfig.fromJson(Map<String, dynamic> json) {
    return PowerCostsConfig(
      oracle: json['ORACLE'] != null
          ? PowerCostConfig.fromJson(json['ORACLE'] as Map<String, dynamic>)
          : fallback.oracle,
      half: json['HALF'] != null
          ? PowerCostConfig.fromJson(json['HALF'] as Map<String, dynamic>)
          : fallback.half,
      skip: json['SKIP'] != null
          ? PowerCostConfig.fromJson(json['SKIP'] as Map<String, dynamic>)
          : fallback.skip,
      skipAll: json['SKIP_ALL'] != null
          ? PowerCostConfig.fromJson(json['SKIP_ALL'] as Map<String, dynamic>)
          : fallback.skipAll,
      timeExtend: json['TIME_EXTEND'] != null
          ? PowerCostConfig.fromJson(json['TIME_EXTEND'] as Map<String, dynamic>)
          : fallback.timeExtend,
      hint: json['HINT'] != null
          ? PowerCostConfig.fromJson(json['HINT'] as Map<String, dynamic>)
          : fallback.hint,
      powerBlock: json['POWER_BLOCK'] != null
          ? PowerCostConfig.fromJson(json['POWER_BLOCK'] as Map<String, dynamic>)
          : fallback.powerBlock,
      powerUnblock: json['POWER_UNBLOCK'] != null
          ? PowerCostConfig.fromJson(json['POWER_UNBLOCK'] as Map<String, dynamic>)
          : fallback.powerUnblock,
    );
  }

  Map<String, dynamic> toJson() => {
    'ORACLE': oracle.toJson(),
    'HALF': half.toJson(),
    'SKIP': skip.toJson(),
    'SKIP_ALL': skipAll.toJson(),
    'TIME_EXTEND': timeExtend.toJson(),
    'HINT': hint.toJson(),
    'POWER_BLOCK': powerBlock.toJson(),
    'POWER_UNBLOCK': powerUnblock.toJson(),
  };

  @override
  List<Object?> get props => [oracle, half, skip, skipAll, timeExtend, hint, powerBlock, powerUnblock];
}
