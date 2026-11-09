import 'dart:async';

import 'package:qulo_v2/core/navigation/navigation.dart';

/// Widget testleri için NavigationService: diyalog cevabı sabit, push/pop/sheet kaydedilir.
/// Gerçek servis router/rootNavigatorKey ister; burada yalnız çağrılar sınanır.
class FakeNavigationService implements NavigationService {
  FakeNavigationService({this.confirmAnswer = true});

  final bool confirmAnswer;

  /// Doluysa diyalog bu tamamlanana kadar açık kalır (çift dokunuş testi).
  Completer<void>? dialogGate;
  final dialogs = <String>[];
  final sheets = <String>[];
  final pushes = <({String name, Object? extra})>[];
  int pops = 0;
  final gos = <String>[];

  /// [isInStack] için yığındaki rota adları (testten verilir).
  final stacked = <String>{};

  @override
  bool isInStack(String name) => stacked.contains(name);

  @override
  Future<T?> showAppDialog<T>(AppDialog dialog) async {
    dialogs.add(dialog.name);
    await dialogGate?.future;
    return confirmAnswer as T;
  }

  /// Sheet secimi (ör. `ListBottomSheet` degeri); null = kullanici kapatti.
  Object? sheetAnswer;

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) async {
    sheets.add(sheet.name);
    return sheetAnswer as T?;
  }

  @override
  Future<T?> push<T extends Object?>(
    String name, {
    Map<String, String>? params,
    Object? extra,
  }) async {
    pushes.add((name: name, extra: extra));
    return null;
  }

  @override
  void go(String name, {Map<String, String>? params, Object? extra}) =>
      gos.add(name);

  @override
  void pop<T>([T? result]) => pops++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeNavigationService.${invocation.memberName}');
}
