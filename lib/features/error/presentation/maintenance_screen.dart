import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';

class MaintenanceScreen extends StatelessWidget {
  final String? message;
  final String? estimatedTime;

  const MaintenanceScreen({
    super.key,
    this.message,
    this.estimatedTime,
  });

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
                Icons.build_circle_rounded,
                size: 16.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 3.h),
              Text(
                'Under Maintenance',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                message ?? 'Our royal kitchens are currently undergoing scheduled upgrades to serve you better. We will be back shortly!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              if (estimatedTime != null) ...[
                SizedBox(height: 3.h),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 18.sp),
                      SizedBox(width: 2.w),
                      Text(
                        'Estimated completion: $estimatedTime',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: 2.h),
              Text(
                'Please check back soon',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
