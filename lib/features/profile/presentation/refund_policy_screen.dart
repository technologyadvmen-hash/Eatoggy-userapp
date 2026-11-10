import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Refunds & Cancellations',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Order Cancellations',
              'You may cancel your order within 60 seconds of placing it for a full refund. Once the restaurant begins preparing the food, cancellations are no longer accepted.',
            ),
            _buildSection(
              '2. Incorrect or Missing Items',
              'If your order is missing items or contains the wrong dish, please contact Support within 12 hours with photographic evidence. We will issue a partial or full refund to your original payment method.',
            ),
            _buildSection(
              '3. Subscription Refunds',
              'Subscription plans (Imperial Weekly / Maharaja Monthly) can be paused or cancelled at any time. Refunds will be prorated based on the number of unutilized meals remaining in your cycle.',
            ),
            _buildSection(
              '4. Refund Processing Time',
              'Approved refunds are processed immediately but may take 5-7 business days to reflect in your bank account or credit card statement, depending on your financial institution.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
