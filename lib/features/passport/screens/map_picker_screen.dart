import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/passport/widgets/q_map_pin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _selectedPosition = const LatLng(41.0082, 28.9784); // Istanbul default
  String? _selectedCity;
  bool _isLoadingCity = false;
  bool _isMapReady = false;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
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
      if (!mounted) return;
      setState(() => _mapStyle = style);

      // setState triggers rebuild, GoogleMap.style property handles it
    } catch (_) {}
  }

  Future<void> _initCurrentLocation() async {
    try {
      final manager = ref.read(locationManagerProvider);
      final permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.granted) {
        final result = await manager.getCurrentPosition();
        if (mounted) {
          setState(() {
            _selectedPosition = LatLng(result.lat, result.lng);
            _selectedCity = result.city;
          });
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLng(_selectedPosition));
        }
      }
    } catch (_) {}
  }

  Future<void> _onCameraIdle() async {
    setState(() => _isLoadingCity = true);
    try {
      final manager = ref.read(locationManagerProvider);
      final city = await manager.getCityFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (mounted) {
        setState(() {
          _selectedCity = city;
          _isLoadingCity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCity = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;
  }

  void _confirm() {
    if (_selectedCity != null) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.passportCitySelect, params: {
        AnalyticsEvents.paramCityName: _selectedCity!,
      });
    }
    Navigator.of(context).pop({
      'lat': _selectedPosition.latitude,
      'lng': _selectedPosition.longitude,
      'city': _selectedCity,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map loading placeholder (if !_isMapReady)
          if (!_isMapReady)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(
                child: AppLoadingWidget.large(),
              ),
            ),

          // 2. Google Map (AnimatedOpacity fade-in)
          AnimatedOpacity(
            opacity: _isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 12,
              ),
              style: _mapStyle,
              onMapCreated: (controller) {
                _mapController.complete(controller);
                setState(() => _isMapReady = true);
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // 3. Q pin (if _isMapReady)
          if (_isMapReady)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: QMapPin(size: 56),
              ),
            ),

          // 4. Back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // 5. Bottom panel — city name + confirm
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
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
                            _selectedCity ?? context.tr('passport_select_location'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isLoadingCity)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: AppLoadingWidget.small(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _selectedCity != null ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: Text(
                        context.tr('passport_move_here'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. My location button — AFTER bottom panel for z-index
          Positioned(
            bottom: 160,
            right: AppSpacing.md,
            child: Material(
              elevation: 6,
              shape: const CircleBorder(),
              color: theme.colorScheme.surface,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _initCurrentLocation,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
