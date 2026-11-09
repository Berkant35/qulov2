import 'package:flutter/widgets.dart';

/// Telefonda "hareketi azalt" açıksa true: efektler son hâline ilk karede gelir.
bool reduceMotionOf(BuildContext context) => MediaQuery.disableAnimationsOf(context);
