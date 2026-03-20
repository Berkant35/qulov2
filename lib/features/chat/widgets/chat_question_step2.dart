import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class ChatQuestionStep2 extends ConsumerStatefulWidget {
  final String matchId;
  final int timeLimitSeconds;
  final String hintText;
  final String? rewardMediaUrl;
  final String? rewardMediaType;
  final bool hasUnmatchRisk;
  final bool hasChatLock;
  final bool hasPowerBlock;
  final void Function({
    int? timeLimitSeconds,
    String? hintText,
    String? rewardMediaUrl,
    String? rewardMediaType,
    bool? hasUnmatchRisk,
    bool? hasChatLock,
    bool? hasPowerBlock,
  }) onChanged;

  const ChatQuestionStep2({
    super.key,
    required this.matchId,
    required this.timeLimitSeconds,
    required this.hintText,
    this.rewardMediaUrl,
    this.rewardMediaType,
    required this.hasUnmatchRisk,
    required this.hasChatLock,
    required this.hasPowerBlock,
    required this.onChanged,
  });

  @override
  ConsumerState<ChatQuestionStep2> createState() => _ChatQuestionStep2State();
}

class _ChatQuestionStep2State extends ConsumerState<ChatQuestionStep2> {
  late final TextEditingController _hintCtrl;
  bool _isUploading = false;

  static const _timerOptions = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _hintCtrl = TextEditingController(text: widget.hintText);
  }

  @override
  void didUpdateWidget(covariant ChatQuestionStep2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintText != _hintCtrl.text) {
      _hintCtrl.text = widget.hintText;
    }
  }

  @override
  void dispose() {
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Timer chips
          _buildLabel(theme, 'Sure Limiti'),
          const SizedBox(height: AppSpacing.sm),
          _TimerChips(
            selectedSeconds: widget.timeLimitSeconds,
            options: _timerOptions,
            onChanged: (v) => widget.onChanged(timeLimitSeconds: v),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Hint text
          _buildLabel(theme, 'Ipucu (opsiyonel)'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _hintCtrl,
            maxLength: 200,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(color: AppColors.textPrimary),
            onChanged: (v) => widget.onChanged(hintText: v),
            decoration: _inputDecoration('Bir ipucu ekleyin...'),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Reward media
          _buildLabel(theme, 'Odul Medyasi (opsiyonel)'),
          const SizedBox(height: AppSpacing.sm),
          _RewardMediaRow(
            rewardMediaUrl: widget.rewardMediaUrl,
            rewardMediaType: widget.rewardMediaType,
            isUploading: _isUploading,
            onPickPhoto: _pickPhoto,
            onRemove: () {
              widget.onChanged(
                rewardMediaUrl: '',
                rewardMediaType: '',
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Unmatch risk
          _SettingSwitch(
            title: 'Unmatch Riski',
            subtitle: 'Yanlis cevap eslemeyi bitirir',
            value: widget.hasUnmatchRisk,
            activeColor: AppColors.error,
            icon: Icons.warning_amber_rounded,
            onChanged: (v) => widget.onChanged(hasUnmatchRisk: v),
          ),
          const SizedBox(height: AppSpacing.md),

          // Chat lock
          _SettingSwitch(
            title: 'Sohbet Kilidi',
            subtitle: 'Cevaplanana kadar sohbet kitlenir',
            value: widget.hasChatLock,
            activeColor: AppColors.primary,
            icon: Icons.lock_outline,
            onChanged: (v) => widget.onChanged(hasChatLock: v),
          ),
          const SizedBox(height: AppSpacing.md),

          // Power block
          _SettingSwitch(
            title: 'Guc Blogu',
            subtitle: widget.hasPowerBlock
                ? 'Aktif'
                : 'Karsi tarafin guclerini engeller',
            value: widget.hasPowerBlock,
            activeColor: AppColors.primaryDark,
            icon: Icons.shield_outlined,
            badge: '40',
            badgeColor: AppColors.primaryDark,
            onChanged: (v) => widget.onChanged(hasPowerBlock: v),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ref.read(imagePickerManagerProvider);
    final picked = await picker.pickFromGallery();
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.uploadMedia(
        widget.matchId,
        bytes: picked.bytes,
        mimeType: picked.mimeType,
      );
      result.when(
        success: (url) {
          widget.onChanged(
            rewardMediaUrl: url,
            rewardMediaType: 'image',
          );
        },
        failure: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).get('chat_media_upload_failed'))),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _TimerChips extends StatelessWidget {
  final int selectedSeconds;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _TimerChips({
    required this.selectedSeconds,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      children: options.map((seconds) {
        final isSelected = selectedSeconds == seconds;
        return ChoiceChip(
          label: Text('${seconds}s'),
          selected: isSelected,
          onSelected: (_) => onChanged(seconds),
          selectedColor: AppColors.primarySurface,
          backgroundColor: AppColors.surfaceInput,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

class _RewardMediaRow extends StatelessWidget {
  final String? rewardMediaUrl;
  final String? rewardMediaType;
  final bool isUploading;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemove;

  const _RewardMediaRow({
    this.rewardMediaUrl,
    this.rewardMediaType,
    required this.isUploading,
    required this.onPickPhoto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = rewardMediaUrl != null && rewardMediaUrl!.isNotEmpty;

    if (hasMedia) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Image.network(
                rewardMediaUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.image, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppLocalizations.of(context).get('chat_media_added'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textHint),
              onPressed: onRemove,
              iconSize: 20,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        _MediaButton(
          icon: Icons.photo_outlined,
          label: AppLocalizations.of(context).get('chat_add_photo'),
          isLoading: isUploading,
          onTap: isUploading ? null : onPickPhoto,
        ),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.icon,
    this.badge,
    this.badgeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
        secondary: Icon(icon, color: value ? activeColor : AppColors.textHint),
        title: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: value ? activeColor : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (badgeColor ?? activeColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badge!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: badgeColor ?? activeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    DiamondIcon.purple(size: 12, showGlow: false),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textHint,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
