import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;

/// Agdan SVG yukler ama ASLA hata firlatmaz; basarisizlikta bos SVG cizer.
///
/// flutter_svg'de yukleyici hata verirse hata, widget onu yakalasa bile, iki
/// yerden yakalanmamis olarak sizar (`svg.cache`'teki onError'suz `.then` ve
/// vector_graphics'te dinlenmeyen `whenComplete`) → `PlatformDispatcher.onError`
/// → Crashlytics'e fatal. Ustelik `SvgNetworkLoader` HTTP durumuna bakmaz:
/// CDN'in 404/429 HTML sayfasini SVG diye parse eder ("name expected").
///
/// Bu yuzden ag hatasi ve derlenemeyen icerik burada yedek SVG'ye cevrilir.
/// Dogrulama flutter_svg'nin kullandigi derleyiciyle, `compute` isolate'inda
/// (provideSvg orada cagrilir) yapilir — ana izlek bloklanmaz.
class SafeSvgNetworkLoader extends SvgNetworkLoader {
  const SafeSvgNetworkLoader(super.url, {super.httpClient});

  static const fallbackSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>';

  @override
  Future<Uint8List?> prepareMessage(BuildContext? context) async {
    try {
      return await super.prepareMessage(context);
    } catch (_) {
      return null;
    }
  }

  @override
  String provideSvg(Uint8List? message) {
    if (message == null) return fallbackSvg;
    final svg = super.provideSvg(message);
    try {
      // flutter_svg'nin kendi secenekleri: optimizer'lar yerel path_ops
      // kutuphanesi ister, acik birakilirsa her gecerli SVG de reddedilir.
      vg.encodeSvg(
        xml: svg,
        debugName: url,
        enableClippingOptimizer: false,
        enableMaskingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      return svg;
    } catch (_) {
      return fallbackSvg;
    }
  }

  // Ust sinifin == kontrolu `is SvgNetworkLoader`; ayni URL'li ham bir
  // yukleyiciyle ayni svg.cache anahtarini paylasmasin.
  @override
  bool operator ==(Object other) => other is SafeSvgNetworkLoader && super == other;

  @override
  int get hashCode => Object.hash(runtimeType, super.hashCode);
}
