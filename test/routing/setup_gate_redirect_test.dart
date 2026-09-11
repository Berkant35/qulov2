import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/routing/setup_gate_redirect.dart';

/// Kurulum kapisi — huninin cekirdegi. Discover'a girmek icin foto + 2 soru +
/// cinsiyet tercihi sart (`UserModel.setupComplete`, sunucu kurali
/// `matching.service.ts` 5.5 ile ayni esikler). Kapi ya kullaniciyi
/// tamamlanmamis profille iceri alir ya da kurulumu bitireni disarida tutarsa
/// huni kirilir; kurulum ekraninin kendi gittigi yerleri engellerse kullanici
/// bir butona basip hicbir sey olmadigini gorur.
UserModel _user({int? age = 27, int photos = 1, int questions = 2, bool genderPref = true}) =>
    UserModel(
      id: 'u1',
      email: 'u1@qulo.test',
      age: age,
      photos: List.generate(photos, (i) => 'https://cdn.example/p$i.jpg'),
      questionCount: questions,
      genderPrefSetAt: genderPref ? DateTime.utc(2026, 9, 1) : null,
    );

String? _gate(String location, UserModel? user) =>
    setupGateRedirect(location: location, user: user);

void main() {
  group('profil henuz yuklenmedi', () {
    for (final location in ['/discover', '/profile-setup', '/profile-completion', '/chat/m1']) {
      test('$location → yonlendirme yok (yanlis ekrana atmaz)', () {
        expect(_gate(location, null), isNull);
      });
    }
  });

  group('yas yok — sosyal giris profili tamamlanmamis', () {
    final noAge = _user(age: null, photos: 0, questions: 0, genderPref: false);

    for (final location in ['/discover', '/profile-setup', '/chat/m1', '/profile/edit']) {
      test('$location → /profile-completion (kurulumdan once gelir)', () {
        expect(_gate(location, noAge), '/profile-completion');
      });
    }

    test('/profile-completion uzerinde kalir', () {
      expect(_gate('/profile-completion', noAge), isNull);
    });
  });

  group('kurulum bitmemis', () {
    final incompleteVariants = {
      'foto yok': _user(photos: 0),
      'tek soru': _user(questions: 1),
      'cinsiyet tercihi yok': _user(genderPref: false),
    };

    incompleteVariants.forEach((label, user) {
      test('$label → discover yerine /profile-setup', () {
        expect(_gate('/discover', user), '/profile-setup');
      });
    });

    final incomplete = _user(photos: 0);

    for (final location in [
      '/matches',
      '/chat/m1',
      '/quiz/t1',
      '/chat-question/q1/solve',
      '/photo-viewer',
    ]) {
      test('$location kapida durur', () {
        expect(_gate(location, incomplete), '/profile-setup');
      });
    }

    // Kurulum ekraninin kendi gittigi yerler (profile_setup_screen:
    // RouteNames.questions; profile_setup_mixin: RouteNames.questionCreate)
    // ve foto/profil duzenleme `/profile` altinda — engellenirse kullanici
    // kapiyi hic gecemez.
    for (final location in [
      '/profile',
      '/profile/questions',
      '/profile/questions/create',
      '/profile/edit',
    ]) {
      test('$location serbest — kurulum akisi', () {
        expect(_gate(location, incomplete), isNull);
      });
    }

    test('onek eslesmesi profil detayini da serbest birakir — quiz yine kapida', () {
      expect(_gate('/profile-detail/u2', incomplete), isNull);
      expect(_gate('/profile/preview', incomplete), isNull);
      expect(_gate('/quiz/u2', incomplete), '/profile-setup');
    });

    test('/questions oneki muaf DEGIL — boyle bir rota yok, sorular /profile altinda', () {
      expect(_gate('/questions/create', incomplete), '/profile-setup');
    });

    test('/profile-setup uzerinde kalir', () {
      expect(_gate('/profile-setup', incomplete), isNull);
    });

    test('/profile-completion yasi olan kullaniciyi discover\'a gonderir', () {
      // Oradan bir sonraki redirect'te kurulum kapisina duser.
      expect(_gate('/profile-completion', incomplete), '/discover');
    });
  });

  group('kurulum tamam', () {
    final complete = _user();

    test('/profile-setup → /discover (tamamlayani disarida tutmaz)', () {
      expect(_gate('/profile-setup', complete), '/discover');
    });

    test('/profile-completion → /discover', () {
      expect(_gate('/profile-completion', complete), '/discover');
    });

    for (final location in ['/discover', '/chat/m1', '/quiz/t1', '/profile']) {
      test('$location → kapi karar vermez', () {
        expect(_gate(location, complete), isNull);
      });
    }

    test('esik tam sinirda gecer — 1 foto, 2 soru', () {
      expect(_gate('/discover', _user(photos: 1, questions: 2)), isNull);
    });
  });
}
