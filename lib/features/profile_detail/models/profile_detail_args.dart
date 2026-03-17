import 'package:qulo_v2/data/models/discover_model.dart';

enum ProfileDetailContext {
  discover,
  match,
  chat,
  quizResult,
}

class ProfileDetailArgs {
  final ProfileDetailContext context;
  final String userId;
  final String? matchId;
  final ProfileCardModel? preloadedCard;

  const ProfileDetailArgs({
    required this.context,
    required this.userId,
    this.matchId,
    this.preloadedCard,
  });
}
