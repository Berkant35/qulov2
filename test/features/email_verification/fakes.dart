import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/auth_repository.dart';
import 'package:qulo_v2/providers/user_provider.dart';

const unverified = UserModel(id: 'u1', email: 'ada@qulo.test');
const verified = UserModel(id: 'u1', email: 'ada@qulo.test', emailVerified: true);

/// `fetchMe` ağa gitmez: sıradaki kullanıcıyı yazar (yoksa mevcut kalır).
class ScriptedUserNotifier extends UserNotifier {
  ScriptedUserNotifier(this._initial, {this.afterFetch});

  final UserModel? _initial;
  final UserModel? afterFetch;
  int fetchCalls = 0;

  @override
  Future<UserModel?> build() async => _initial;

  @override
  Future<void> fetchMe() async {
    fetchCalls++;
    if (afterFetch != null) state = AsyncData(afterFetch);
  }
}

class FakeResendAuthRepository implements AuthRepository {
  FakeResendAuthRepository(this.resendResult);

  final Result<ResendVerificationResponse> resendResult;
  int resendCalls = 0;

  @override
  Future<Result<ResendVerificationResponse>> resendVerification() async {
    resendCalls++;
    return resendResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeResendAuthRepository.${invocation.memberName}');
}

/// Alt sayfayı göstermez; açılan sayfaların adını kaydeder.
class RecordingNavigationService implements NavigationService {
  RecordingNavigationService({this.sheetResult});

  final Object? sheetResult;
  final sheets = <String>[];

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) async {
    sheets.add(sheet.name);
    return sheetResult as T?;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('RecordingNavigationService.${invocation.memberName}');
}
