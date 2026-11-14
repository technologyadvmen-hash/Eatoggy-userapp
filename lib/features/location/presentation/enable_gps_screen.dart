import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class EnableGpsScreen extends StatelessWidget {
  const EnableGpsScreen({super.key});

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
              Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_disabled_rounded,
                  size: 25.w,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Location Disabled',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Eatoggy requires your device location to find the best restaurants near you and deliver your food hot and fresh.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 6.h),
              PrimaryGoldButton(
                text: 'Enable GPS',
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'I\'ll do it later',
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
