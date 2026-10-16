import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                  Icons.gpp_bad_rounded,
                  size: 18.w,
                  color: AppColors.error,
                ),
                SizedBox(height: 3.h),
                Text(
                  'Security Alert',
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'We have detected that this device may be rooted, jailbroken, or running in an unauthorized environment. For your safety and to protect your payment data, the Eatoggy app cannot run on this device.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6.h),
                PrimaryGoldButton(
                  text: 'Exit Application',
                  onPressed: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
