import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using the Eatoggy application, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              '2. Service Description',
              'Eatoggy provides a premium platform for users to order food from our curated partner restaurants and subscribe to our royal tiffin services.',
            ),
            _buildSection(
              '3. User Account',
              'You are responsible for maintaining the confidentiality of your account and OTPs. Eatoggy reserves the right to refuse service, terminate accounts, or cancel orders in its sole discretion.',
            ),
            _buildSection(
              '4. Pricing and Payment',
              'All prices are subject to change without notice. We use third-party payment gateways (Razorpay) and do not store your credit card details.',
            ),
            _buildSection(
              '5. Delivery Policy',
              'Delivery times are estimates and may vary based on weather, traffic, and restaurant preparation time. We are not liable for unavoidable delays.',
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
