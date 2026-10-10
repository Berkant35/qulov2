import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Widget testlerinde `userProvider`'ı sabit bir kullanıcıyla başlatır:
/// `userProvider.overrideWith(() => FixedUserNotifier(user))`.
/// `fetchMe` gibi ağ çağrıları gerekmiyorsa fake repository yerine bunu kullan.
class FixedUserNotifier extends UserNotifier {
  FixedUserNotifier(this._user);

  final UserModel _user;

  @override
  Future<UserModel?> build() async => _user;
}
