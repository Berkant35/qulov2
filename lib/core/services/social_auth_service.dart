import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialSignInResult {
  final String provider;
  final String idToken;
  final String? name;
  final String? surname;
  final String? nonce;

  const SocialSignInResult({
    required this.provider,
    required this.idToken,
    this.name,
    this.surname,
    this.nonce,
  });
}

class SocialAuthService {
  SocialAuthService._();
  static final instance = SocialAuthService._();

  Future<SocialSignInResult> signInWithGoogle() async {
    await GoogleSignIn.instance.signOut();

    final account = await GoogleSignIn.instance.authenticate();

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in: no ID token');
    }

    final nameParts = (account.displayName ?? '').split(' ');
    final name = nameParts.isNotEmpty ? nameParts.first : null;
    final surname =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

    return SocialSignInResult(
      provider: 'google',
      idToken: idToken,
      name: name,
      surname: surname,
    );
  }

  Future<SocialSignInResult> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple sign-in: no identity token');
    }

    return SocialSignInResult(
      provider: 'apple',
      idToken: idToken,
      name: credential.givenName,
      surname: credential.familyName,
      nonce: rawNonce,
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
