import 'dart:typed_data';

import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/data/models/power_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/models/support_ticket_model.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';

// ─── Auth ───
abstract class IAuthRepository {
  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    required String genderPref,
    double? lat,
    double? lng,
    String locale = 'tr',
  });

  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> verifyEmail(String token);

  Future<Result<RefreshResponse>> refresh(String refreshToken);

  Future<Result<void>> logout({String? refreshToken});

  Future<Result<void>> forgotPassword(String email);

  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  });
}

// ─── Chat ───
abstract class IChatRepository {
  Future<Result<MessagesResponse>> getMessages(String matchId, {int page = 1, int limit = 30});

  Future<Result<MessageModel>> sendMessage(String matchId, {required String content, bool isImage = false, String? audioUrl, int? audioDurationSeconds});

  Future<Result<void>> markAsRead(String matchId);

  Future<Result<void>> deleteMessage(String matchId, String messageId);

  Future<Result<Map<String, dynamic>>> addReaction(String matchId, String messageId, String emoji);

  Future<Result<MediaRequestModel>> requestMedia(String matchId);

  Future<Result<Map<String, dynamic>>> respondToMediaRequest(String matchId, String requestId, String action);

  Future<Result<void>> disableMedia(String matchId);

  Future<Result<MediaStatusResponse>> getMediaStatus(String matchId);
}

// ─── Exchange ───
abstract class IExchangeRepository {
  Future<Result<ConvertResponse>> convert(int greenAmount);
  Future<Result<BuyPowerResponse>> buyPower(String powerName, String diamondType, int quantity);
  Future<Result<InventoryResponse>> getInventory();
  Future<Result<RatesResponse>> getRates();
}

// ─── Diamond ───
abstract class IDiamondRepository {
  Future<Result<DiamondBalance>> getBalance();

  Future<Result<DiamondHistoryResponse>> getHistory({int page = 1, int limit = 20});

  Future<Result<void>> purchase(String iapProductId, {String? transactionId});
}

// ─── Match ───
abstract class IMatchRepository {
  Future<Result<DiscoverResponse>> discover({int page = 1});

  Future<Result<SwipeResponse>> swipe({required String targetId, required String action});

  Future<Result<List<MatchModel>>> getMatches();

  Future<Result<ProfileCardModel>> undoSwipe(String targetId);

  Future<Result<void>> unmatch(String matchId);
}

// ─── Passport ───
abstract class IPassportRepository {
  Future<Result<Map<String, dynamic>>> activate({
    required String city,
    required double lat,
    required double lng,
  });

  Future<Result<void>> deactivate();
}

// ─── Power ───
abstract class IPowerRepository {
  Future<Result<List<PowerModel>>> getPowers();
}

// ─── Question ───
abstract class IQuestionRepository {
  Future<Result<List<QuestionModel>>> getMyQuestions();

  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data);

  Future<Result<QuestionModel>> updateQuestion(int orderNum, Map<String, dynamic> data);

  Future<Result<void>> deleteQuestion(int orderNum);

  Future<Result<int>> getQuestionCount();

  Future<Result<List<QuestionModel>>> reorderQuestions(List<String> orderedIds);
}

// ─── Quiz ───
abstract class IQuizRepository {
  Future<Result<QuizStartResponse>> startSession(String targetId);

  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId);

  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,
    String? powerUsed,
    int? timeSpent,
  });

  Future<Result<QuizAnswerResponse>> rescueWithSkip(String sessionId, {String powerType = 'SKIP'});

  Future<Result<QuizAnswerResponse>> failSession(String sessionId);

  Future<Result<QuizResultModel>> getSessionResult(String sessionId);
}

// ─── Report ───
abstract class IReportRepository {
  Future<Result<void>> createReport({
    required String reportedId,
    required String category,
    String? reason,
    String? description,
  });
}

// ─── Subscription ───
abstract class ISubscriptionRepository {
  Future<Result<SubscriptionInfo>> getStatus();
}

// ─── Referral ───
abstract class IReferralRepository {
  Future<Result<String>> getMyCode();

  Future<Result<ReferralStats>> getStats();

  Future<Result<List<ReferralItem>>> getHistory();

  Future<Result<ValidateCodeResponse>> validateCode(String code);

  Future<Result<String>> applyCode(String code);
  Future<Result<MyReferrerResponse>> getMyReferrer();
}

// ─── User ───
abstract class IUserRepository {
  Future<Result<UserModel>> getMe();

  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data);

  Future<Result<UserDetailsModel>> updateDetails(Map<String, dynamic> data);

  Future<Result<void>> updateLocation({required double lat, required double lng, String? city});

  Future<Result<void>> updatePushToken(String token);

  Future<Result<void>> heartbeat();

  Future<Result<Map<String, dynamic>>> uploadPhoto(Uint8List bytes, String mimeType);

  Future<Result<Map<String, dynamic>>> deletePhoto(int index);

  Future<Result<void>> deleteAccount();

  Future<Result<Map<String, dynamic>>> boost();

  Future<Result<Map<String, dynamic>>> claimBadgeReward(String level);

  Future<Result<Map<String, dynamic>>> setInterests(List<String> interests);

  Future<Result<Map<String, dynamic>>> quickAssignQuestions();

  Future<Result<UserModel>> reorderPhotos(List<String> photos);

  Future<Result<PublicProfileModel>> getPublicProfile(String userId);
}

// ─── Block ───
abstract class IBlockRepository {
  Future<Result<void>> blockUser(String blockedId);
  Future<Result<void>> unblockUser(String blockedId);
  Future<Result<List<Map<String, dynamic>>>> getBlockedUsers();
}

// ─── SupportTicket ───
abstract class ISupportTicketRepository {
  Future<Result<SupportTicketModel>> createTicket({
    required String subject,
    required String message,
    required String category,
  });
  Future<Result<List<SupportTicketModel>>> getMyTickets();
  Future<Result<SupportTicketModel>> getTicket(String id);
}
