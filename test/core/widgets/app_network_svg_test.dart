import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/app_network_svg.dart';

void main() {
  test('isSvgUrl: yol .svg ile bitiyorsa true; sorgu/parça ve harf büyüklüğü önemsiz', () {
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/logos/grab.svg'), isTrue);
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/logos/GRAB.SVG'), isTrue);
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/logos/grab.svg?v=3#x'), isTrue);
  });

  test('isSvgUrl: resim uzantısı, sorguda geçen svg ve bozuk URL false', () {
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/logos/grab.png'), isFalse);
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/logo?format=.svg'), isFalse);
    expect(AppNetworkSvg.isSvgUrl('https://cdn.example/svg/grab'), isFalse);
    expect(AppNetworkSvg.isSvgUrl('http://[::1'), isFalse);
  });
}
