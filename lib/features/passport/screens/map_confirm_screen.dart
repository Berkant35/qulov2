import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/passport/widgets/q_map_pin.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

class MapConfirmScreen extends ConsumerStatefulWidget {
  const MapConfirmScreen({
    super.key,
    required this.cityName,
    required this.country,
    required this.flag,
    required this.lat,
    required this.lng,
  });

  final String cityName;
  final String country;
  final String flag;
  final double lat;
  final double lng;

  @override
  ConsumerState<MapConfirmScreen> createState() => _MapConfirmScreenState();
}

class _MapConfirmScreenState extends ConsumerState<MapConfirmScreen> with LoadingMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isMapReady = false;
  String? _mapStyle;

  // Draggable position state
  late LatLng _currentPosition;
  late String _currentCity;
  bool _isLoadingCity = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(widget.lat, widget.lng);
    _currentCity = widget.cityName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.passportMapConfirmView, params: {
        AnalyticsEvents.paramDestinationCity: widget.cityName,
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final brightness = Theme.of(context).brightness;
    final path = brightness == Brightness.dark
        ? 'assets/map/map_style_dark.json'
        : 'assets/map/map_style_light.json';
    try {
      final style = await rootBundle.loadString(path);
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    if (!mounted) return;
    setState(() => _isLoadingCity = true);
    try {
      final service = ref.read(teleportServiceProvider);
      final city = await service.reverseGeocode(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      if (mounted) {
        setState(() {
          if (city != null && city.isNotEmpty) _currentCity = city;
          _isLoadingCity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCity = false);
    }
  }

  Future<void> _onConfirm() async {
    final nav = ref.read(navigationServiceProvider);
    final cityToActivate = _currentCity;
    final latToActivate = _currentPosition.latitude;
    final lngToActivate = _currentPosition.longitude;

    await withLoading(() async {
      final passport = ref.read(passportProvider);
      final Result result;
      if (passport.isActive) {
        result = await ref.read(passportProvider.notifier).changeCity(
          city: cityToActivate, lat: latToActivate, lng: lngToActivate,
        );
      } else {
        result = await ref.read(passportProvider.notifier).activate(
          city: cityToActivate, lat: latToActivate, lng: lngToActivate,
        );
      }

      result.when(
        success: (_) {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.passportExploreStart, params: {
            AnalyticsEvents.paramDestinationCity: cityToActivate,
          });
          nav.pop();
        },
        failure: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('passport_activate_failed'))),
            );
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialTarget = LatLng(widget.lat, widget.lng);

    return Scaffold(
      body: Stack(
        children: [
          // Loading placeholder
          if (!_isMapReady)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(child: AppLoadingWidget.large()),
            ),

          // Google Map — draggable
          AnimatedOpacity(
            opacity: _isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12),
              style: _mapStyle,
              onMapCreated: (controller) async {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                setState(() => _isMapReady = true);
                // Zoom animation for premium feel
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: initialTarget, zoom: 14),
                    ),
                  );
                }
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              // Draggable — user can fine-tune location
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // Center pin with drop animation
          if (_isMapReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -50, end: 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    );
                  },
                  child: const QMapPin(size: 56),
                ),
              ),
            ),

          // Back button top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref.read(navigationServiceProvider).pop(),
              ),
            ),
          ),

          // Bottom confirm panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // City name row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _isLoadingCity ? 0.4 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _currentCity,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isLoadingCity)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: SizedBox(width: 16, height: 16, child: AppLoadingWidget.small()),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : _onConfirm,
                      style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                          : Text(context.tr('passport_start_exploring')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
