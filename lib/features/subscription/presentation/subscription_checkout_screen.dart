import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'package:sizer/sizer.dart';
import '../../../shared/models/models.dart';

class SubscriptionCheckoutScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionCheckoutScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  State<SubscriptionCheckoutScreen> createState() => _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends State<SubscriptionCheckoutScreen> {
  bool _isProcessing = false;

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    // Simulate network payment
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      context.push('/subscription-calendar', extra: widget.subscription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.subscription.plan;
    final basePrice = plan.pricePerMeal * plan.totalMeals;
    final tax = basePrice * 0.05;
    final grandTotal = basePrice + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Confirm Plan',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Plan Summary
              _buildSectionHeader('Plan Summary'),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: AppColors.secondaryText, size: 16.sp),
                        SizedBox(width: 2.w),
                        Text(
                          '${plan.totalMeals} Meals • ${plan.durationDays} Days',
                          style: GoogleFonts.outfit(
                            color: AppColors.secondaryText,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // 2. Delivery Address
              _buildSectionHeader('Delivery Address'),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24.sp),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Home',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primaryText,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Change',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '12, Royal Palm Avenue, Sector 5\nBandra West, Mumbai 400050',
                            style: GoogleFonts.outfit(
                              color: AppColors.secondaryText,
                              fontSize: 13.sp,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // 3. Bill Summary
              _buildSectionHeader('Bill Summary'),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildBillRow('Base Plan (${plan.totalMeals} Meals)', '₹${basePrice.toStringAsFixed(2)}'),
                    SizedBox(height: 1.h),
                    _buildBillRow('Taxes & GST (5%)', '₹${tax.toStringAsFixed(2)}'),
                    SizedBox(height: 1.h),
                    _buildBillRow('Delivery Fee', 'FREE', isDiscount: true),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      child: const Divider(color: AppColors.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To Pay',
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
          child: GestureDetector(
            onTap: _isProcessing ? null : _handlePayment,
            child: Container(
              width: double.infinity,
              height: 7.h,
              decoration: BoxDecoration(
                color: _isProcessing ? AppColors.muted : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Pay & Start Subscription',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.primaryText,
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.secondaryText,
            fontSize: 14.sp,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.outfit(
            color: isDiscount ? Colors.green : AppColors.primaryText,
            fontSize: 14.sp,
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
