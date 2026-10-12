import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/splash_cubit.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _letterSpacing;
  late final Animation<double> _shimmerSweep;

  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();

    // 1. Primary Entrance Controller (1200ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Dynamic Zoom with energetic spring-back
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Smooth Entrance Fade
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Subtle Express Slide up into dock
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline Staggered Reveal
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _letterSpacing = Tween<double>(begin: 4.5, end: 2.2).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Ambient Concentric Pulse Waves (1800ms continuous loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 3. Shimmer Gleam Sweep (1400ms periodic)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _shimmerSweep = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Start entrance animation
    _introController.forward().then((_) {
      if (mounted) {
        _shimmerController.repeat(reverse: false, period: const Duration(milliseconds: 2200));
      }
    });

    // Check if cubit is already in a completed state (e.g. Activity recreation from background)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SplashCubit>();
      if (cubit.state is SplashNavigateToHome) {
        context.go(AppRoutes.home);
      } else if (cubit.state is SplashNavigateToOnboarding) {
        context.go(AppRoutes.onboarding);
      } else if (cubit.state is SplashNavigateToLogin) {
        context.go(AppRoutes.login);
      } else {
        cubit.initSplash();
      }
    });

    // Safety watchdog: Splash screen must never hang; guarantees unauthenticated users never enter home screen
    _watchdogTimer = Timer(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      final state = context.read<SplashCubit>().state;
      if (state is! SplashNavigateToHome &&
          state is! SplashNavigateToOnboarding &&
          state is! SplashNavigateToLogin) {
        try {
          final prefs = await SharedPreferencesService.getInstance();
          final token = prefs.getString(AppKeys.accessToken);
          if (token != null && token.trim().isNotEmpty && token != 'null') {
            if (mounted) context.go(AppRoutes.home);
          } else {
            if (mounted) context.go(AppRoutes.login);
          }
        } catch (_) {
          if (mounted) context.go(AppRoutes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToHome) {
          context.go(AppRoutes.home);
        } else if (state is SplashNavigateToOnboarding) {
          context.go(AppRoutes.onboarding);
        } else if (state is SplashNavigateToLogin) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Background Subtle Warm Luxury Glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.1),
                    radius: 1.1,
                    colors: [
                      Color(0xFFFFF9F0),
                      Color(0xFFFAF7F2),
                    ],
                  ),
                ),
              ),
            ),

            // Concentric Sonic Energy Waves behind the speed logo
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final progress = _pulseController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding ring
                    Container(
                      width: 140 + (progress * 180),
                      height: 140 + (progress * 180),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(
                            alpha: (1.0 - progress).clamp(0.0, 0.16),
                          ),
                          width: 2.0,
                        ),
                      ),
                    ),
                    // Inner secondary ring
                    Container(
                      width: 90 + (((progress + 0.5) % 1.0) * 140),
                      height: 90 + (((progress + 0.5) % 1.0) * 140),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(
                            alpha: (1.0 - ((progress + 0.5) % 1.0)).clamp(0.0, 0.14),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Hero Speed Logo with Spring Zoom & Shimmer Gleam
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/eatoggy_speed_logo.png',
                            width: 64.w,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 64.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.primary,
                                    size: 10.w,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Diagonal Shimmer Light Gleam across Logo
                          AnimatedBuilder(
                            animation: _shimmerSweep,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 64.w,
                                  height: 14.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(
                                        _shimmerSweep.value - 1.0,
                                        -0.8,
                                      ),
                                      end: Alignment(
                                        _shimmerSweep.value,
                                        0.8,
                                      ),
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Staggered Brand Tagline & Velocity Indicator
            Positioned(
              bottom: 10.h,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: SlideTransition(
                  position: _taglineSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _letterSpacing,
                        builder: (context, child) {
                          return Text(
                            'EATOGGY',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: _letterSpacing.value,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 0.8.h),
                      Text(
                        'GOURMET HOMESTYLE • EXPRESS VELOCITY',
                        style: GoogleFonts.outfit(
                          color: AppColors.secondaryText,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(height: 2.2.h),
                      // Smooth Dynamic Gradient Track Loader
                      SizedBox(
                        width: 28.w,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            color: AppColors.primary,
                            backgroundColor: Color(0xFFE7E5E4),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
