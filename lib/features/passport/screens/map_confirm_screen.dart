import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/passport/mixins/map_confirm_screen_mixin.dart';
import 'package:qulo_v2/features/passport/widgets/map_confirm_bottom_panel.dart';
import 'package:qulo_v2/features/passport/widgets/q_map_pin.dart';

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

class _MapConfirmScreenState extends ConsumerState<MapConfirmScreen>
    with LoadingMixin, MapConfirmScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadMapStyle();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialTarget = LatLng(widget.lat, widget.lng);

    return Scaffold(
      body: Stack(
        children: [
          // Loading placeholder
          if (!isMapReady)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(child: AppLoadingWidget.large()),
            ),

          // Google Map
          AnimatedOpacity(
            opacity: isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12),
              style: mapStyle,
              onMapCreated: (controller) async {
                if (!mapController.isCompleted) {
                  mapController.complete(controller);
                }
                setState(() => isMapReady = true);
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: initialTarget, zoom: 14),
                    ),
                  );
                }
              },
              onCameraMove: onCameraMove,
              onCameraIdle: onCameraIdle,
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
          if (isMapReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -50, end: 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(offset: Offset(0, value), child: child);
                  },
                  child: const QMapPin(size: 56),
                ),
              ),
            ),

          // Back button
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
          MapConfirmBottomPanel(
            cityName: currentCity,
            isLoadingCity: isLoadingCity,
            isLoading: isLoading,
            onConfirm: onConfirm,
          ),
        ],
      ),
    );
  }
}
