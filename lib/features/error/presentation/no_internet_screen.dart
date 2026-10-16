import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'assets/eatoggy_speed_logo.png',
                  width: 44.w,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 3.h),
              Icon(
                Icons.wifi_off_rounded,
                size: 18.w,
                color: AppColors.muted,
              ),
              SizedBox(height: 3.h),
              Text(
                'No Connection',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'It looks like you are offline. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 6.h),
              PrimaryGoldButton(
                text: 'Try Again',
                onPressed: () {
                  if (onRetry != null) {
                    onRetry!();
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
