import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../widgets/custom_widgets.dart';

class NotFoundScreen extends StatelessWidget {
  final String? path;

  const NotFoundScreen({super.key, this.path});

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
                Icons.restaurant_menu_rounded,
                size: 25.w,
                color: AppColors.muted,
              ),
              SizedBox(height: 3.h),
              Text(
                '404',
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'We couldn\'t find the dish you\'re looking for.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 2.h),
              if (path != null)
                Text(
                  'Missing route: $path',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              SizedBox(height: 6.h),
              PrimaryGoldButton(
                text: 'Return Home',
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
