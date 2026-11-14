import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/services/storage_service.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigateToOnboarding extends SplashState {}

class SplashNavigateToLogin extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initSplash() async {
    emit(SplashLoading());

    // Fetch dynamic backend configuration and keys in parallel
    unawaited(AppConfigService.instance.fetchRemoteConfig());

    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final prefs = await SharedPreferencesService.getInstance();
      final token = prefs.getString(AppKeys.accessToken);

      if (token != null && token.trim().isNotEmpty && token != 'null') {
        emit(SplashNavigateToHome());
      } else {
        final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
        if (onboardingDone) {
          emit(SplashNavigateToLogin());
        } else {
          emit(SplashNavigateToOnboarding());
        }
      }
    } catch (_) {
      emit(SplashNavigateToLogin());
    }
  }
}
