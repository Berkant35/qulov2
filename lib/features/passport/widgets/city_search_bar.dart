import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/teleport_service.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class CitySearchBar extends ConsumerStatefulWidget {
  const CitySearchBar({super.key, required this.onCitySelected});
  final void Function(TeleportCity city) onCitySelected;

  @override
  ConsumerState<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends ConsumerState<CitySearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<TeleportCity> _results = [];
  bool _isSearching = false;
  bool _hasError = false;
  bool _showResults = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() { _results = []; _showResults = false; _hasError = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() { _isSearching = true; _hasError = false; });
    try {
      final service = ref.read(teleportServiceProvider);
      final results = await service.searchCities(query);
      if (!mounted) return;
      setState(() { _results = results; _isSearching = false; _showResults = true; _hasError = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _results = []; _isSearching = false; _showResults = true; _hasError = true; });
    }
  }

  void _selectCity(TeleportCity city) {
    _controller.clear();
    _focusNode.unfocus();
    setState(() { _results = []; _showResults = false; });
    widget.onCitySelected(city);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: context.tr('passport_search_placeholder'),
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
            suffixIcon: _isSearching
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: AppLoadingWidget.small()))
                : _controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textHint), onPressed: () { _controller.clear(); setState(() { _results = []; _showResults = false; }); })
                    : null,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          ),
        ),
        if (_showResults && !_isSearching) ...[
          const SizedBox(height: AppSpacing.xs),
          if (_hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text(context.tr('passport_search_failed'), style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
            )
          else if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text(context.tr('passport_no_results'), style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final city = _results[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city, size: 20, color: AppColors.primary),
                    title: Text(city.name, style: theme.textTheme.bodyMedium),
                    subtitle: Text(city.fullName, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
