import 'package:flutter/material.dart';
import 'package:qulo_v2/core/widgets/app_network_svg.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';

/// Kanal logosu (icon_url, SVG) varsa onu, yoksa emojiyi gosterir.
/// Logo yuklenirken emoji yer tutucudur.
class AcquisitionChannelIcon extends StatelessWidget {
  const AcquisitionChannelIcon({super.key, required this.channel});

  final AcquisitionChannel channel;

  @override
  Widget build(BuildContext context) {
    final emojiWidget = channel.hasEmoji
        ? Text(channel.emoji!, style: Theme.of(context).textTheme.headlineMedium)
        : null;
    if (!channel.hasLogo) {
      return emojiWidget ?? const SizedBox.shrink();
    }
    return AppNetworkSvg(url: channel.iconUrl!, placeholder: emojiWidget);
  }
}
