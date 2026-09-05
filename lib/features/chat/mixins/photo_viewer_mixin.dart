import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Sohbetteki gorsel yuzeylerinin ortak "tam ekran ac" davranisi.
///
/// Ucu de ayni Hero etiketi ile ayni route'u actigi icin cagri tek yerde
/// toplanir; widget'lar dogrudan `Navigator`/`MaterialPageRoute` kullanmaz.
mixin PhotoViewerMixin {
  void openPhotoViewer(WidgetRef ref, String imageUrl, {String? heroTag}) {
    ref.read(navigationServiceProvider).push<void>(
      RouteNames.photoViewer,
      extra: {'imageUrl': imageUrl, 'heroTag': heroTag},
    );
  }
}
