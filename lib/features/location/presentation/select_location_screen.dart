import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';
import '../data/models/add_address_response.dart';
import '../data/models/serviceability_response.dart';
import '../data/repositories/serviceability_repository.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final ServiceabilityRepository _serviceabilityRepository = ServiceabilityRepositoryImpl();
  final Geocoding _geocoding = Geocoding();

  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _isCheckingServiceability = false;
  bool _isLocatingUser = false;
  ServiceabilityResponse? _serviceability;

  // Selected or detected coordinates (defaults to Beed, Maharashtra)
  double _currentLat = 18.9891;
  double _currentLng = 75.7601;
  String _locationTitle = 'Beed City';
  String _locationSubtitle = 'Beed, Maharashtra 431122';
  String _detectedCity = 'Beed';
  String _detectedState = 'Maharashtra';
  String _detectedPincode = '431122';

  final TextEditingController _flatHouseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  @override
  void dispose() {
    _flatHouseController.dispose();
    _landmarkController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // _darkMapStyle removed for light aesthetic

  @override
  void initState() {
    super.initState();
    _loadInitialLocationAndCheck();
  }

  Future<void> _loadInitialLocationAndCheck() async {
    final prefs = await SharedPreferencesService.getInstance();
    final savedLat = prefs.getDouble(AppKeys.latitude);
    final savedLng = prefs.getDouble(AppKeys.longitude);
    final savedAddr = prefs.getString(AppKeys.currentAddress);

    // If coordinates were the old Gurugram default, auto-locate to current real GPS
    final bool isOldGurugramDefault = savedLat != null &&
        savedLng != null &&
        savedLat > 28.45 &&
        savedLat < 28.47 &&
        savedLng > 77.02 &&
        savedLng < 77.03;

    if (savedLat != null && savedLng != null && !isOldGurugramDefault) {
      _currentLat = savedLat;
      _currentLng = savedLng;
      if (savedAddr != null && savedAddr.isNotEmpty) {
        final addrParts = savedAddr.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (addrParts.length > 2) {
          _locationTitle = addrParts.take(2).join(', ');
          _locationSubtitle = addrParts.skip(2).join(', ');
        } else if (addrParts.isNotEmpty) {
          _locationTitle = addrParts.first;
          _locationSubtitle = savedAddr;
        }
      }
      _checkAreaServiceability();
    } else {
      // Auto-detect real device location (e.g. Beed, Maharashtra)
      await _locateCurrentUser(animate: false);
    }
  }

  Future<void> _checkAreaServiceability() async {
    setState(() {
      _isCheckingServiceability = true;
    });

    try {
      final result = await _serviceabilityRepository.checkServiceability(
        latitude: _currentLat,
        longitude: _currentLng,
      );
      if (mounted) {
        setState(() {
          _serviceability = result;
          _isCheckingServiceability = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingServiceability = false;
        });
      }
    }
  }

  Future<void> _onCameraIdle() async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(_currentLat, _currentLng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;

        final streetElements = <String>[];
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty &&
            place.subThoroughfare != place.locality) {
          streetElements.add(place.subThoroughfare!);
        }
        if (place.thoroughfare != null &&
            place.thoroughfare!.isNotEmpty &&
            place.thoroughfare != place.locality &&
            !streetElements.contains(place.thoroughfare)) {
          streetElements.add(place.thoroughfare!);
        }
        if (place.street != null &&
            place.street!.isNotEmpty &&
            place.street != place.locality &&
            !streetElements.any((e) => place.street!.contains(e))) {
          streetElements.add(place.street!);
        }
        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.locality &&
            place.name != place.administrativeArea &&
            !streetElements.contains(place.name)) {
          streetElements.insert(0, place.name!);
        }

        String? subLoc = (place.subLocality != null &&
                place.subLocality!.isNotEmpty &&
                place.subLocality != place.locality)
            ? place.subLocality
            : null;

        String exactTitle;
        if (streetElements.isNotEmpty) {
          if (subLoc != null && !streetElements.any((e) => e.contains(subLoc))) {
            exactTitle = '${streetElements.join(', ')}, $subLoc';
          } else {
            exactTitle = streetElements.join(', ');
          }
        } else if (subLoc != null) {
          exactTitle = subLoc;
        } else {
          exactTitle = place.locality ?? 'Selected Location';
        }

        final parts = <String>[];
        if (subLoc != null && !exactTitle.contains(subLoc)) {
          parts.add(subLoc);
        }
        if (place.locality != null &&
            place.locality!.isNotEmpty &&
            !exactTitle.contains(place.locality!)) {
          parts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            place.subAdministrativeArea != place.locality &&
            !parts.contains(place.subAdministrativeArea)) {
          parts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          parts.add(place.postalCode!);
        }

        final sub = parts.isNotEmpty
            ? parts.join(', ')
            : (place.administrativeArea ?? 'Maharashtra, India');

        setState(() {
          _locationTitle = exactTitle;
          _locationSubtitle = sub;
          _detectedCity = place.locality ?? place.subAdministrativeArea ?? 'Beed';
          _detectedState = place.administrativeArea ?? 'Maharashtra';
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            _detectedPincode = place.postalCode!;
          }
        });
      }
    } catch (_) {}

    _checkAreaServiceability();
  }

  Future<void> _locateCurrentUser({bool animate = true}) async {
    if (!mounted) return;
    setState(() => _isLocatingUser = true);
    try {
      final bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        // Location service is off
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && animate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission is disabled. Please enable it in Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        final currentPos = pos;
        setState(() {
          _currentLat = currentPos.latitude;
          _currentLng = currentPos.longitude;
        });
        if (animate) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(currentPos.latitude, currentPos.longitude), zoom: 16.5),
            ),
          );
        }
        await _onCameraIdle();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isServiceable = _serviceability?.isServiceable ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Google Map View
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat, _currentLng),
                zoom: 16.0,
              ),
              // Removed style: _darkMapStyle to use default light map
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: LatLng(_currentLat, _currentLng), zoom: 16.0),
                  ),
                );
              },
              onCameraMove: (pos) {
                _currentLat = pos.target.latitude;
                _currentLng = pos.target.longitude;
              },
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
          ),

          // 2. Center Location Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Deliver Here',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // 3. Search header
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.muted.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.muted.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locationTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. GPS "Locate Me" Button
          Positioned(
            right: 16,
            bottom: 300,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.surface),
              ),
              onPressed: _isLocatingUser ? null : _locateCurrentUser,
              child: _isLocatingUser
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary, size: 20),
            ),
          ),

          // 5. Bottom card with address & serviceability details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppConstants.p20,
                right: AppConstants.p20,
                top: AppConstants.p20,
                bottom: AppConstants.p20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
                border: Border(top: BorderSide(color: AppColors.surface, width: 1.2)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _locationTitle,
                              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 17),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _locationSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // Optional Exact Building / Flat input
                      TextField(
                        controller: _flatHouseController,
                        style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          hintText: 'House / Flat / Floor / Building No. (Optional)',
                          hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.surface),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.surface),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Optional Landmark input
                      TextField(
                        controller: _landmarkController,
                        style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          hintText: 'Landmark / Nearby Place (Optional)',
                          hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.surface),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.surface),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          prefixIcon: const Icon(Icons.near_me_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Serviceability status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCheckingServiceability
                              ? Colors.grey.withValues(alpha: 0.15)
                              : isServiceable
                                  ? const Color(0xFFE8F5E9)
                                  : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isCheckingServiceability
                                ? AppColors.muted
                                : isServiceable
                                    ? const Color(0xFF34C759)
                                    : AppColors.primary.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isCheckingServiceability) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Checking kitchen serviceability...',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                                ),
                              ),
                            ] else if (isServiceable) ...[
                              const Icon(Icons.check_circle_outline, color: Color(0xFF34C759), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Available',
                                      style: TextStyle(
                                        color: Color(0xFF34C759),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Estimated delivery: ~${_serviceability?.estimatedDeliveryMinutes ?? 35} mins'
                                      '${_serviceability?.kitchenName != null ? ' • ${_serviceability!.kitchenName}' : ''}',
                                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Coverage Zone (${_detectedCity.isNotEmpty ? _detectedCity : 'Delivery'})',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      'Gourmet dispatch & pre-orders active for your selected area',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                      PrimaryGoldButton(
                        text: 'Confirm Location',
                        isLoading: _isLoading,
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          final prefs = await SharedPreferencesService.getInstance();
                          await prefs.setDouble(AppKeys.latitude, _currentLat);
                          await prefs.setDouble(AppKeys.longitude, _currentLng);

                          final flatText = _flatHouseController.text.trim();
                          final landmarkText = _landmarkController.text.trim();

                          final exactLine1 = flatText.isNotEmpty
                              ? '$flatText, $_locationTitle'
                              : _locationTitle;
                          final exactLine2 = landmarkText.isNotEmpty
                              ? '$landmarkText, $_locationSubtitle'
                              : _locationSubtitle;
                          final fullAddr = '$exactLine1, $exactLine2'.trim();

                          await prefs.setString(AppKeys.currentAddress, fullAddr);
                          await prefs.setString('current_pincode', _detectedPincode);
                          await prefs.setString('current_city', _detectedCity);

                          try {
                            final cachedStr = prefs.getString('cached_customer_addresses');
                            List<dynamic> list = [];
                            if (cachedStr != null && cachedStr.isNotEmpty) {
                              final decoded = jsonDecode(cachedStr);
                              if (decoded is List) list = decoded;
                            }
                            final newAddr = CustomerAddressData(
                              id: 'addr_current_loc',
                              customerId: '',
                              name: flatText.isNotEmpty ? flatText : _locationTitle,
                              mobile: prefs.getString(AppKeys.userPhone) ?? '',
                              addressLine1: exactLine1,
                              addressLine2: exactLine2,
                              landmark: landmarkText.isNotEmpty ? landmarkText : null,
                              city: _detectedCity.isNotEmpty
                                  ? _detectedCity
                                  : (_locationSubtitle.split(',').length > 1
                                      ? _locationSubtitle.split(',')[1].trim()
                                      : 'Beed'),
                              state: _detectedState.isNotEmpty ? _detectedState : 'Maharashtra',
                              pincode: _detectedPincode.isNotEmpty ? _detectedPincode : '431122',
                              label: 'Current Location',
                              isDefault: true,
                            );
                            list.removeWhere((item) =>
                                item is Map &&
                                (item['id'] == 'addr_current_loc' || item['id'] == 'addr_selected_loc'));
                            list.insert(0, newAddr.toJson());
                            await prefs.setString('cached_customer_addresses', jsonEncode(list));
                          } catch (_) {}

                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          if (mounted && context.mounted) {
                            if (context.canPop()) {
                              context.pop(true);
                            }
                          }
                        },
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
  }
}
