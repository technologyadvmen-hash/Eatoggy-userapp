import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class RateLimitScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const RateLimitScreen({super.key, this.onRetry});

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
              Icon(
                Icons.hourglass_empty_rounded,
                size: 25.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 3.h),
              Text(
                'Too Many Requests',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'You\'re moving too fast! Please wait a moment before trying again to ensure a smooth experience.',
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
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
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
