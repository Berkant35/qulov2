import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/audio_player_manager.dart';
import 'package:qulo_v2/features/questions/widgets/question_voice_preview.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Önizleme kapanınca (kaldırma, yeni kayıt, ekrandan çıkış) kendi çaldığı
/// sesi susturur — tekil oynatıcı başka ekranda çalmaya devam etmesin.
mixin QuestionVoicePreviewMixin on ConsumerState<QuestionVoicePreview> {
  late final AudioPlayerManager _player;

  void initPreview() => _player = ref.read(audioPlayerManagerProvider);

  void onSourceChanged(String oldSource) {
    if (oldSource != widget.source) _stopIfPlaying(oldSource);
  }

  void disposePreview() => _stopIfPlaying(widget.source);

  void _stopIfPlaying(String source) {
    if (_player.currentUrl == source) unawaited(_player.stop());
  }
}
