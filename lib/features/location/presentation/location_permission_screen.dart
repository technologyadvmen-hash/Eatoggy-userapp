import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../widgets/custom_widgets.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocationBloc(),
      child: const _LocationPermissionView(),
    );
  }
}

class _LocationPermissionView extends StatefulWidget {
  const _LocationPermissionView();

  @override
  State<_LocationPermissionView> createState() => _LocationPermissionViewState();
}

class _LocationPermissionViewState extends State<_LocationPermissionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _proceedToHome() {
    if (!mounted) return;
    _watchdogTimer?.cancel();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationSuccess) {
            _proceedToHome();
          } else if (state is LocationSkipped) {
            _proceedToHome();
          } else if (state is LocationFailure) {
            Helpers.showErrorSnackbar('Location Access', state.message);
            // Never trap user on permission screen — proceed to home with default location
            _proceedToHome();
          }
        },
        builder: (context, state) {
          final bool isLoading = state is LocationLoading;
          final String loadingMessage =
              state is LocationLoading ? state.message : '';

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Center Graphic: Radial Pulse Glow & Location Pin Icon matching SVG layout
                  Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFE7E5E4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFE4E8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 16.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),

                  // Title
                  Text(
                    'Enable Location Services',
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryText,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.5.h),

                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      isLoading && loadingMessage.isNotEmpty
                          ? loadingMessage
                          : 'To discover premium kitchen hub slots near you and ensure flawless gourmet delivery scheduling.',
                      style: GoogleFonts.inter(
                        color: isLoading
                            ? AppColors.primary
                            : AppColors.secondaryText,
                        fontSize: 14.5.sp,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(),

                  // Primary Button: Allow Location Access
                  PrimaryGoldButton(
                    text: 'Allow Location Access',
                    isLoading: isLoading,
                    onPressed: () {
                      // Arm watchdog safety timer: max 6 seconds before moving forward
                      _watchdogTimer?.cancel();
                      _watchdogTimer = Timer(const Duration(seconds: 6), () {
                        if (mounted) {
                          context.read<LocationBloc>().add(const SkipLocationEvent());
                        }
                      });

                      context
                          .read<LocationBloc>()
                          .add(const RequestCurrentLocationEvent());
                    },
                  ),
                  SizedBox(height: 1.8.h),

                  // Secondary Button: Remind Later
                  GestureDetector(
                    onTap: () {
                      context
                          .read<LocationBloc>()
                          .add(const SkipLocationEvent());
                    },
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE7E5E4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Remind Later',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF78716C),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
