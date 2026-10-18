import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/storage_service.dart';
import '../data/models/serviceability_response.dart';
import '../data/repositories/serviceability_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final Geocoding _geocoding = Geocoding();
  final ServiceabilityRepository _serviceabilityRepository;

  static const double fallbackLat = 28.6139;
  static const double fallbackLng = 77.2090;
  static const String fallbackAddress = 'Connaught Place, New Delhi';
  static const String fallbackCity = 'New Delhi';
  static const String fallbackPincode = '110001';

  LocationBloc({ServiceabilityRepository? serviceabilityRepository})
      : _serviceabilityRepository = serviceabilityRepository ?? ServiceabilityRepositoryImpl(),
        super(const LocationInitial()) {
    on<RequestCurrentLocationEvent>(_onRequestCurrentLocation);
    on<SkipLocationEvent>(_onSkipLocation);
    on<OpenLocationSettingsEvent>(_onOpenLocationSettings);
    on<OpenAppSettingsEvent>(_onOpenAppSettings);
  }

  Future<void> _saveLocationToPrefs(
    double lat,
    double lng,
    String address,
    String city,
    String pincode,
  ) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.setDouble(AppKeys.latitude, lat);
      await prefs.setDouble(AppKeys.longitude, lng);
      await prefs.setString(AppKeys.currentAddress, address);
      await prefs.setString('current_city', city);
      await prefs.setString('current_pincode', pincode);
    } catch (_) {}
  }

  Future<void> _onRequestCurrentLocation(
    RequestCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading(message: 'Checking GPS service...'));

    try {
      // 1. Check if device location service is enabled with quick timeout
      bool isServiceEnabled = false;
      try {
        isServiceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
      } catch (_) {
        isServiceEnabled = false;
      }

      if (!isServiceEnabled) {
        // Fallback gracefully so user is never blocked from entering the home screen
        await _saveLocationToPrefs(fallbackLat, fallbackLng, fallbackAddress, fallbackCity, fallbackPincode);
        emit(const LocationSuccess(
          latitude: fallbackLat,
          longitude: fallbackLng,
          address: fallbackAddress,
        ));
        return;
      }

      // 2. Check and request runtime permission with timeout
      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 8), onTimeout: () => LocationPermission.denied);
        }
      } catch (_) {
        permission = LocationPermission.denied;
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Fallback gracefully so user is never trapped
        await _saveLocationToPrefs(fallbackLat, fallbackLng, fallbackAddress, fallbackCity, fallbackPincode);
        emit(const LocationSuccess(
          latitude: fallbackLat,
          longitude: fallbackLng,
          address: fallbackAddress,
        ));
        return;
      }

      emit(const LocationLoading(message: 'Detecting your coordinates...'));

      // 3. Acquire GPS Position (with fallback to last known and strict 3s timeout)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {
        try {
          position = await Geolocator.getLastKnownPosition()
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
        } catch (_) {
          position = null;
        }
      }

      if (position == null) {
        // Fallback gracefully to default coordinates
        await _saveLocationToPrefs(fallbackLat, fallbackLng, fallbackAddress, fallbackCity, fallbackPincode);
        emit(const LocationSuccess(
          latitude: fallbackLat,
          longitude: fallbackLng,
          address: fallbackAddress,
        ));
        return;
      }

      emit(const LocationLoading(message: 'Resolving your address...'));

      // 4. Reverse Geocoding to get human-readable address
      String formattedAddress = '';
      String city = fallbackCity;
      String pincode = fallbackPincode;
      try {
        final List<Placemark> placemarks = await _geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final String subLocality = place.subLocality ?? place.name ?? '';
          final String locality = place.locality ?? place.subAdministrativeArea ?? '';

          if (subLocality.isNotEmpty && locality.isNotEmpty) {
            formattedAddress = '$subLocality, $locality';
          } else if (locality.isNotEmpty) {
            formattedAddress = locality;
          } else if (subLocality.isNotEmpty) {
            formattedAddress = subLocality;
          }

          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            pincode = place.postalCode!;
          }
          final c = place.locality ?? place.subAdministrativeArea;
          if (c != null && c.isNotEmpty) {
            city = c;
          }
        }
      } catch (_) {
        // Fallback gracefully if geocoding fails
      }

      if (formattedAddress.isEmpty) {
        formattedAddress = 'Current Location';
      }

      // 5. Save location details in SharedPreferences
      await _saveLocationToPrefs(position.latitude, position.longitude, formattedAddress, city, pincode);

      // 6. Check area serviceability (API: GET /api/serviceability/check?lat=...&lng=...)
      ServiceabilityResponse? serviceability;
      try {
        serviceability = await _serviceabilityRepository.checkServiceability(
          latitude: position.latitude,
          longitude: position.longitude,
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}

      emit(LocationSuccess(
        latitude: position.latitude,
        longitude: position.longitude,
        address: formattedAddress,
        serviceability: serviceability,
      ));
    } catch (_) {
      // In case of any unhandled error, save fallback and proceed to home
      await _saveLocationToPrefs(fallbackLat, fallbackLng, fallbackAddress, fallbackCity, fallbackPincode);
      emit(const LocationSuccess(
        latitude: fallbackLat,
        longitude: fallbackLng,
        address: fallbackAddress,
      ));
    }
  }

  Future<void> _onSkipLocation(
    SkipLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    final prefs = await SharedPreferencesService.getInstance();
    if (prefs.getString(AppKeys.currentAddress) == null ||
        prefs.getString(AppKeys.currentAddress)!.isEmpty) {
      await _saveLocationToPrefs(fallbackLat, fallbackLng, fallbackAddress, fallbackCity, fallbackPincode);
    }
    emit(const LocationSkipped());
  }

  Future<void> _onOpenLocationSettings(
    OpenLocationSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _onOpenAppSettings(
    OpenAppSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    await Geolocator.openAppSettings();
  }
}
