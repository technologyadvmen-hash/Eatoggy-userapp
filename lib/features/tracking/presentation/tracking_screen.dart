import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../data/models/order_tracking_model.dart';
import '../../../widgets/custom_widgets.dart';

class TrackingScreen extends StatelessWidget {
  final Order? order;
  final String? orderId;

  const TrackingScreen({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final targetOrderId = order?.id ?? orderId ?? 'EAT-88902';
    final deliveryAddrStr = order != null
        ? '${order!.address.flatHouse}, ${order!.address.street}, ${order!.address.city}'
        : null;

    return BlocProvider(
      create: (context) => TrackingCubit()
        ..loadTracking(targetOrderId, fallbackAddress: deliveryAddrStr)
        ..startPolling(targetOrderId),
      child: _TrackingScreenContent(orderId: targetOrderId, order: order),
    );
  }
}

class _TrackingScreenContent extends StatefulWidget {
  final String orderId;
  final Order? order;

  const _TrackingScreenContent({
    required this.orderId,
    this.order,
  });

  @override
  State<_TrackingScreenContent> createState() => _TrackingScreenContentState();
}

class _TrackingScreenContentState extends State<_TrackingScreenContent> {
  GoogleMapController? _mapController;
  double? _deviceLat;
  double? _deviceLng;

  @override
  void initState() {
    super.initState();
    _loadDeviceCoords();
  }

  Future<void> _loadDeviceCoords() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final lat = prefs.getDouble(AppKeys.latitude);
      final lng = prefs.getDouble(AppKeys.longitude);
      if (lat != null && lng != null && mounted) {
        setState(() {
          _deviceLat = lat;
          _deviceLng = lng;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _recenterMap(LatLng restaurantPos, LatLng riderPos, LatLng destPos) {
    if (_mapController == null) return;
    try {
      final points = [restaurantPos, riderPos, destPos];
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (_) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(restaurantPos, 13.5),
      );
    }
  }

  void _showDeliveryInstructions(BuildContext context, String instructions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Instructions',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    instructions.isNotEmpty ? instructions : 'Leave parcel with security gate / Ring bell.',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingCubit, TrackingState>(
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty && !state.isRefreshing) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.error!, style: const TextStyle(color: AppColors.primaryText)),
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final tracking = state.trackingData ??
            OrderTrackingModel.mock(
              widget.orderId,
              lat: _deviceLat,
              lng: _deviceLng,
            );
        final rider = tracking.rider;

        final double destLatitude = tracking.deliveryLat ?? (_deviceLat ?? 18.9894);
        final double destLongitude = tracking.deliveryLng ?? (_deviceLng ?? 75.7601);
        final destPos = LatLng(destLatitude, destLongitude);

        // Restaurant Position (The Great Kitchen, Gurugram from live API)
        final restaurantPos = LatLng(
          tracking.restaurantLat ?? 28.4384,
          tracking.restaurantLng ?? 77.0988,
        );

        final riderPos = (rider.latitude != null && rider.longitude != null)
            ? LatLng(rider.latitude!, rider.longitude!)
            : (destPos.latitude > 28.0)
                ? LatLng(destPos.latitude - 0.005, destPos.longitude - 0.004)
                : LatLng(restaurantPos.latitude + 0.003, restaurantPos.longitude + 0.003);

        final markers = <Marker>{
          Marker(
            markerId: const MarkerId('restaurant'),
            position: restaurantPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(
              title: tracking.restaurantName,
              snippet: 'Kitchen • ${tracking.restaurantAddress}',
            ),
          ),
          Marker(
            markerId: const MarkerId('rider'),
            position: riderPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: rider.name,
              snippet: 'Valet Partner • ${rider.vehicleNumber}',
            ),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: destPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Your Delivery Location',
              snippet: tracking.deliveryAddress,
            ),
          ),
        };

        final polylines = <Polyline>{
          Polyline(
            polylineId: const PolylineId('delivery_path'),
            points: [restaurantPos, riderPos, destPos],
            color: AppColors.primary,
            width: 4,
            geodesic: true,
          ),
        };

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── 1. Real Google Maps Layer ────────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: restaurantPos,
                    zoom: 13.5,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),

              // ── 2. Top Header Controls (Back, Live Badge, Refresh) ───────
              Positioned(
                top: 6.h,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          router.go('/orders');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xCC11110F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xEE11110F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          const _PulsingLiveDot(),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE TRACKING',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: state.isRefreshing
                          ? null
                          : () => context.read<TrackingCubit>().refreshTracking(widget.orderId),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xCC11110F),
                          shape: BoxShape.circle,
                        ),
                        child: state.isRefreshing
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                                color: AppColors.primary,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. Floating Re-Center / Fit Route Button ─────────────────
              Positioned(
                right: 16,
                bottom: 46.h,
                child: GestureDetector(
                  onTap: () => _recenterMap(restaurantPos, riderPos, destPos),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xEE161614),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.7), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),

              // ── 4. Bottom Tracking Details Sheet ────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(maxHeight: 52.h),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Status & ETA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tracking.statusDisplay,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tracking.eta.isNotEmpty ? 'Arriving in ${tracking.eta}' : 'Arriving Soon',
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.6), width: 1.0),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield_outlined, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Hot-case Insulated',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Kitchen / Restaurant Info Card ──────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.restaurant, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PREPARED AT',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondaryText,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text(
                                              'Verified Kitchen',
                                              style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tracking.restaurantName,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tracking.restaurantAddress,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColors.secondaryText,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Delivery Destination Card ────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.green, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DELIVERING TO',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondaryText,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tracking.deliveryAddress,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.primaryText,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Delivery OTP Banner ──────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary, width: 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DELIVERY OTP',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryText,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Share this code with rider',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tracking.deliveryOtp,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(color: AppColors.border, height: 24, thickness: 1),

                          // Rider details row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(rider.avatar),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rider.name,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: AppColors.primary, size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${rider.rating} • ${rider.vehicleNumber}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Phone Call Trigger
                              _buildRoundActionBtn(
                                Icons.call_outlined,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Calling Valet Partner: ${rider.phone}'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              // Chat Trigger
                              _buildRoundActionBtn(
                                Icons.chat_bubble_outline,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Opening secure valet delivery chat...'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Delivery Instructions Button
                          SpeedAnimatedButton(
                            text: 'View Delivery Instructions',
                            height: 50,
                            borderRadius: BorderRadius.circular(12),
                            textStyle: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            onPressed: () => _showDeliveryInstructions(context, tracking.instructions),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoundActionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: _opacityAnimation.value),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
