import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class CrashScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CrashScreen({super.key, required this.errorDetails});

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
                Icons.warning_amber_rounded,
                size: 18.w,
                color: AppColors.error,
              ),
              SizedBox(height: 3.h),
              Text(
                'Oops! Something Broke.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Our culinary architects have been notified and are fixing the issue immediately.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                height: 15.h,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    errorDetails.exceptionAsString(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              PrimaryGoldButton(
                text: 'Restart Application',
                onPressed: () {
                  // In a real app, this might restart the root navigator
                  // For now, we pop the crash screen if possible
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
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
