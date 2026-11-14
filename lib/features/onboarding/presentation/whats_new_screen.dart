import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VERSION 4.12.0',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "What's New in\n",
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryText,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Eatoggy?',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureItem(
                      icon: Icons.diamond_rounded,
                      title: 'Luxury UI Overhaul',
                      description: 'Experience our brand new Ivory and Imperial Red Royal design system across the entire application.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.flash_on_rounded,
                      title: 'Lightning Fast Search',
                      description: 'We have optimized the food search engine to bring you the best culinary experiences instantly.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.security_rounded,
                      title: 'Enhanced Security',
                      description: 'New robust payment integrations and environmental security checks to keep your data safe.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Imperial Tiffin Plans',
                      description: 'Subscribe to our exclusive Weekly and Monthly home-cooked meal deliveries directly from the app.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              PrimaryGoldButton(
                text: 'Continue to App',
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: AppColors.secondaryText,
                    fontSize: 11.5.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
