import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bellek-ici guvenli depo. Interceptor yalnizca read/write/deleteAll
/// kullaniyor; gerisi noSuchMethod ile patlar.
class FakeSecureStorage implements FlutterSecureStorage {
  FakeSecureStorage(Map<String, String> initial) : values = {...initial};

  final Map<String, String> values;
  bool failWrites = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        if (failWrites) {
          return Future<void>.error(PlatformException(code: 'errSecInteractionNotAllowed'));
        }
        values[key!] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      case #deleteAll:
        values.clear();
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
