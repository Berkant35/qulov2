import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// [MyTicketsScreen] icin sunum-disi logic.
mixin MyTicketsScreenMixin {
  /// Talep olusturma ekranini acar; yeni talep olustuysa listeyi tazeler.
  Future<void> openCreateTicket(
    WidgetRef ref,
    ProviderBase<Object?> listProvider,
  ) async {
    final created = await ref
        .read(navigationServiceProvider)
        .push<bool>(RouteNames.createTicket);
    if (created == true) ref.invalidate(listProvider);
  }
}

/// [_TicketListItem] icin sunum-disi eslemeler.
mixin TicketListItemWidgetMixin {
  /// Talep durumunu tema rengine esler.
  Color statusColor(BuildContext context, String status) {
    return switch (status) {
      'OPEN' => context.appColors.warning,
      'IN_PROGRESS' => context.appColors.info,
      'RESOLVED' => context.appColors.success,
      _ => context.appColors.textHint,
    };
  }
}
