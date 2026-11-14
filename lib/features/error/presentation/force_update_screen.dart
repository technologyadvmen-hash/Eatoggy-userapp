import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _launchStore() async {
    final String url = Platform.isIOS
        ? 'https://apps.apple.com/app/idYOUR_APP_ID' // Replace with actual App Store ID
        : 'https://play.google.com/store/apps/details?id=com.eatoggy.userapp'; // Replace with actual Play Store ID
        
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
                Icons.system_update_rounded,
                size: 16.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Update Required',
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'We\'ve added fresh speed enhancements to our app! Please update to the latest version to continue enjoying the seamless Eatoggy experience.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 6.h),
              PrimaryGoldButton(
                text: 'Update Now',
                onPressed: _launchStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
