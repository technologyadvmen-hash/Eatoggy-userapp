import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/network_exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../data/models/get_profile_request.dart';
import '../data/models/get_profile_response.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

import '../data/models/update_profile_request.dart';

export 'profile_event.dart';
export 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
    on<RefreshProfileEvent>(_onRefreshProfile);
    on<UpdateCustomerProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onUpdateProfile(
    UpdateCustomerProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    ProfileCustomer? currentCustomer;
    if (state is ProfileLoaded) {
      currentCustomer = (state as ProfileLoaded).customer;
    }

    try {
      final request = UpdateProfileRequest(
        name: event.name,
        email: event.email,
        dietaryPreference: event.dietaryPreference,
        avatar: event.avatar,
      );

      final response = await _profileRepository.updateProfile(request);
      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      ProfileCustomer updated;
      if (data['data'] != null && data['data'] is Map<String, dynamic>) {
        final innerData = data['data'] as Map<String, dynamic>;
        updated = (innerData['customer'] != null && innerData['customer'] is Map<String, dynamic>)
            ? ProfileCustomer.fromJson(innerData['customer'] as Map<String, dynamic>)
            : ProfileCustomer.fromJson(innerData);
      } else if (currentCustomer != null) {
        updated = currentCustomer.copyWith(
          name: event.name,
          email: event.email,
          dietaryPreference: event.dietaryPreference,
          avatar: event.avatar,
        );
      } else {
        await _loadProfile(emit);
        return;
      }

      emit(ProfileLoaded(
        customer: updated,
        message: data['message']?.toString() ?? 'Profile updated successfully',
      ));
    } on DioException catch (e) {
      emit(ProfileFailure(error: NetworkExceptions.getErrorMessage(e)));
      if (currentCustomer != null) {
        emit(ProfileLoaded(customer: currentCustomer));
      }
    } catch (e) {
      emit(ProfileFailure(error: e.toString()));
      if (currentCustomer != null) {
        emit(ProfileLoaded(customer: currentCustomer));
      }
    }
  }

  Future<void> _onFetchProfile(
    FetchProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    await _loadProfile(emit);
  }

  Future<void> _onRefreshProfile(
    RefreshProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    await _loadProfile(emit);
  }

  static const String _profileCacheKey = 'cached_customer_profile';

  Future<void> _loadProfile(Emitter<ProfileState> emit) async {
    try {
      final response = await _profileRepository.getProfile(
        request: const GetProfileRequest(),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final profileResponse = GetProfileResponse.fromJson(data);

      if (profileResponse.success && profileResponse.data?.customer != null) {
        final cust = profileResponse.data!.customer!;
        emit(ProfileLoaded(
          customer: cust,
          message: profileResponse.message,
        ));
        try {
          final prefs = await SharedPreferencesService.getInstance();
          await prefs.setString(_profileCacheKey, jsonEncode(cust.toJson()));
        } catch (_) {}
      } else {
        await _fallbackToCachedProfile(emit, profileResponse.message);
      }
    } on DioException catch (e) {
      await _fallbackToCachedProfile(emit, NetworkExceptions.getErrorMessage(e));
    } catch (e) {
      await _fallbackToCachedProfile(emit, e.toString());
    }
  }

  Future<void> _fallbackToCachedProfile(Emitter<ProfileState> emit, String fallbackError) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final cachedStr = prefs.getString(_profileCacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is Map<String, dynamic>) {
          emit(ProfileLoaded(customer: ProfileCustomer.fromJson(decoded)));
          return;
        }
      }
    } catch (_) {}
    emit(ProfileFailure(error: fallbackError.isNotEmpty ? fallbackError : 'Failed to retrieve customer profile.'));
  }
}
