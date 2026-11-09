import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';
import 'package:qulo_v2/features/settings/widgets/delete_reason_sheet.dart';

import '../../../helpers/fake_navigation.dart';

/// Hesap silme neden sheet'i. Veri (son 30 gün): 41 `other` kaydının 38'inde
/// metin boş, 2.0.13'ten beri `skipped` hiç yok. Sebep: modal sheet klavyeye yer
/// açmıyordu, "Diğer" metin alanı klavyenin altında kalıyordu.
class _ClosingNav extends FakeNavigationService {
  final closed = <Object?>[];

  @override
  void closeOverlay<T>([T? result]) => closed.add(result);
}

const _screen = Size(390, 844);
const _keyboard = 336.0;

void main() {
  late _ClosingNav nav;

  /// Sheet'i NavigationService ile aynı ayarlarla (tall faktör) açar.
  Future<void> openSheet(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = _screen;
    addTearDown(tester.view.reset);
    nav = _ClosingNav();
    await tester.pumpWidget(ProviderScope(
      overrides: [navigationServiceProvider.overrideWithValue(nav)],
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: _screen.height * AppBottomSheet.tallHeightFactor,
                ),
                builder: (_) => const DeleteReasonSheet(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle(); // l10n delegesi yüklensin
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> selectOther(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
  }

  Future<void> showKeyboard(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
    await tester.pumpAndSettle();
  }

  testWidgets('"Diğer" seçilince metin alanı odaklanır ve klavye açıkken görünür kalır',
      (tester) async {
    await openSheet(tester);
    await selectOther(tester);
    await showKeyboard(tester);

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    final keyboardTop = _screen.height - _keyboard;
    expect(tester.getRect(field).bottom, lessThanOrEqualTo(keyboardTop),
        reason: 'metin alanı klavyenin altında kalmamalı');
    // Eylem butonları da klavyenin üstünde, erişilebilir.
    expect(tester.getRect(find.text('Delete Account')).bottom, lessThanOrEqualTo(keyboardTop));
    expect(tester.takeException(), isNull, reason: 'taşma (overflow) yok');
  });

  testWidgets('"Diğer" + yazılan metin → other + kırpılmış metin gider', (tester) async {
    await openSheet(tester);
    await selectOther(tester);
    await tester.enterText(find.byType(TextField), '  bildirim çok fazla  ');
    await tester.tap(find.text('Delete Account'));

    final result = nav.closed.single! as DeleteReasonResult;
    expect(result.reasonCode, 'other');
    expect(result.reasonText, 'bildirim çok fazla');
  });

  testWidgets('"Diğer" + boş metin → yine `other` gider (skipped DEĞİL), metin yok', (tester) async {
    await openSheet(tester);
    await selectOther(tester);
    await tester.tap(find.text('Delete Account'));

    final result = nav.closed.single! as DeleteReasonResult;
    expect(result.reasonCode, 'other');
    expect(result.reasonText, isNull);
  });

  testWidgets('"Neden belirtmeden devam et" → skipped gider', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Continue without a reason'));

    final result = nav.closed.single! as DeleteReasonResult;
    expect(result.reasonCode, kDeletionReasonSkipped);
    expect(result.reasonText, isNull);
  });

  testWidgets('neden seçilmeden "Hesabı Sil" pasif', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Delete Account'));

    expect(nav.closed, isEmpty);
  });
}
