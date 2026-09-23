import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_channel_tile.dart';

/// Kanal listesi + (serbest metin kanalı seçiliyse) metin alanı + Devam.
/// Atla yok: her kullanıcı bir satır seçer ("Hatırlamıyorum" dahil) —
/// 20–23 Eyl'de 7 cevabın 7'si atlanmıştı, skip yerine veri.
class AcquisitionChannelList extends StatelessWidget {
  const AcquisitionChannelList({
    super.key,
    required this.channels,
    required this.selectedId,
    required this.onSelect,
    required this.freeformController,
    required this.submitting,
    required this.onSubmit,
  });

  final List<AcquisitionChannel> channels;
  final String? selectedId;
  final ValueChanged<AcquisitionChannel> onSelect;

  /// Yalnız serbest metin kanalı seçiliyken verilir; null ise alan gösterilmez.
  final TextEditingController? freeformController;
  final bool submitting;

  /// null → Devam kapalı (seçim yok ya da gönderim sürüyor).
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in channels)
          AcquisitionChannelTile(
            channel: c,
            selected: selectedId == c.id,
            onTap: () => onSelect(c),
          ),
        if (freeformController != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextField(
              controller: freeformController,
              decoration: InputDecoration(hintText: context.tr('acq_other_hint')),
              maxLength: AppConstants.acquisitionFreeformMaxLength,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: onSubmit,
          child: submitting
              ? const AppLoadingWidget.small()
              : Text(context.tr('acq_continue')),
        ),
      ],
    );
  }
}
