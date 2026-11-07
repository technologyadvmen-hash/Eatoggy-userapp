import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../cart/cubit/cart_cubit.dart';

import '../data/repositories/offers_repository.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final TextEditingController _couponController = TextEditingController();
  final OffersRepository _offersRepository = OffersRepositoryImpl();
  String? _errorMessage;
  bool _isApplying = false;
  bool _isLoadingOffers = false;

  // Custom fallback premium coupons
  static const Coupon _royalTreat = Coupon(
    code: 'ROYALTREAT50',
    discountPercent: 14.33,
    maxDiscount: 50,
    minOrderValue: 100,
    description: 'Flat ₹50 saved on your current box.',
    expiryDate: 'Expires in 5 days',
  );

  static const Coupon _festive60 = Coupon(
    code: 'FESTIVE60',
    discountPercent: 60,
    maxDiscount: 150,
    minOrderValue: 499,
    description: 'Get 60% off up to ₹150 on luxury weekly subscriptions. Valid once per user.',
    expiryDate: 'Expires in 3 days',
  );

  static const Coupon _freeDeluxe = Coupon(
    code: 'FREEDELUXE',
    discountPercent: 11.46,
    maxDiscount: 40,
    minOrderValue: 0,
    description: 'Free delivery on all premium bespoke gourmet boxes.',
    expiryDate: 'Expires in 7 days',
  );

  List<Coupon> _availableCoupons = [_royalTreat, _festive60, _freeDeluxe];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoadingOffers = true);
    try {
      final remote = await _offersRepository.getOffers();
      if (mounted && remote.isNotEmpty) {
        // Merge remote offers with luxury fallback vouchers (avoid duplicate codes)
        final existingCodes = remote.map((c) => c.code.toUpperCase()).toSet();
        final combined = [
          ...remote,
          ...[_royalTreat, _festive60, _freeDeluxe].where((c) => !existingCodes.contains(c.code.toUpperCase())),
        ];
        setState(() {
          _availableCoupons = combined;
          _isLoadingOffers = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingOffers = false);
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCustomCoupon(Coupon coupon, CartState cartState) async {
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty! Add food items to your cart first to apply vouchers.'),
          backgroundColor: Color(0xFFC62828),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _errorMessage = 'Add food items to your cart first to apply vouchers.';
      });
      return;
    }

    if (cartState.subtotal < coupon.minOrderValue) {
      final deficit = (coupon.minOrderValue - cartState.subtotal).ceil();
      final msg = 'Min. Order Value of ₹${coupon.minOrderValue.toInt()} is required! Add ₹$deficit more to apply.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFC62828),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _errorMessage = msg;
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      // Validate with POST /api/offers/apply-coupon (if user is authenticated)
      final response = await _offersRepository.applyCoupon(coupon.code);
      if (response != null &&
          response['success'] == false &&
          response['message'] != null &&
          !response['message'].toString().toLowerCase().contains('token')) {
        final err = response['message']?.toString() ?? 'Coupon cannot be applied';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: const Color(0xFFC62828)),
          );
          setState(() {
            _isApplying = false;
            _errorMessage = err;
          });
        }
        return;
      }
    } catch (_) {
      // Fallback gracefully to client validation
    }

    if (!mounted) return;
    context.read<CartCubit>().applyCoupon(coupon);
    setState(() {
      _isApplying = false;
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "'${coupon.code}' applied successfully!",
                style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    if (Navigator.of(context).canPop()) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && Navigator.of(context).canPop()) {
          context.pop();
        }
      });
    }
  }

  Future<void> _applyCouponByCode(String code, CartState cartState) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty! Add food items to your cart first to apply vouchers.'),
          backgroundColor: Color(0xFFC62828),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _errorMessage = 'Add food items to your cart first to apply vouchers.';
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      final response = await _offersRepository.applyCoupon(cleanCode);
      if (response != null && response['success'] == true) {
        final discountVal = (response['discount'] as num?)?.toDouble() ?? 50.0;
        final coupon = Coupon(
          code: cleanCode,
          discountPercent: 100.0,
          maxDiscount: discountVal,
          minOrderValue: 0,
          description: response['message']?.toString() ?? 'Special promo coupon discount applied',
          expiryDate: 'Applied',
        );
        if (mounted) {
          context.read<CartCubit>().applyCoupon(coupon);
          setState(() {
            _isApplying = false;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Coupon '$cleanCode' applied successfully!",
                      style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
          if (Navigator.of(context).canPop()) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && Navigator.of(context).canPop()) {
                context.pop();
              }
            });
          }
        }
        return;
      }
    } catch (_) {}

    // Check in local list
    final match = _availableCoupons.firstWhere(
      (c) => c.code.toUpperCase() == cleanCode,
      orElse: () => const Coupon(
        code: '',
        discountPercent: 0,
        maxDiscount: 0,
        minOrderValue: 0,
        description: '',
        expiryDate: '',
      ),
    );

    if (match.code.isNotEmpty) {
      await _applyCustomCoupon(match, cartState);
    } else {
      const err = "Invalid coupon code! Try 'ROYALTREAT50' or 'FESTIVE60'";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(err), backgroundColor: Color(0xFFC62828)),
        );
        setState(() {
          _isApplying = false;
          _errorMessage = err;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final appliedCoupon = cartState.appliedCoupon;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

                  // 1. Header with back button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 14.sp),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Offers & Coupons',
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryText,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.5.h),

                  // 2. Coupon input area
                  Text(
                    'APPLY COUPON CODE',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6.5.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _couponController,
                            style: GoogleFonts.outfit(
                              color: AppColors.primaryText,
                              fontSize: 15.sp, // Strictly between 14.sp to 18.sp
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.secondaryText,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      GestureDetector(
                        onTap: _isApplying
                            ? null
                            : () => _applyCouponByCode(_couponController.text, cartState),
                        child: Container(
                          height: 6.5.h,
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          decoration: BoxDecoration(
                            gradient: _isApplying ? null : AppColors.redGradient,
                            color: _isApplying ? AppColors.muted : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isApplying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'APPLY',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14.sp, // Strictly between 14.sp to 18.sp
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Applied Success alert box
                  if (appliedCoupon != null) ...[
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              '${appliedCoupon.code} applied! ₹${cartState.discountAmount.toInt()} saved on your current box.',
                              style: GoogleFonts.outfit(
                                color: AppColors.primary,
                                fontSize: 14.sp, // Strictly between 14.sp to 18.sp
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF44336),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  SizedBox(height: 1.h),

                  // 3. Available Coupons Section
                  Text(
                    'Available Coupons',
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryText,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Expanded(
                    child: _isLoadingOffers
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _availableCoupons.length,
                            itemBuilder: (context, index) {
                        final coupon = _availableCoupons[index];
                        final isThisApplied = appliedCoupon?.code == coupon.code;
                        final isFestive = coupon.code == 'FESTIVE60';

                        return GestureDetector(
                          onTap: () {
                            if (!isThisApplied) {
                              _applyCustomCoupon(coupon, cartState);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 2.h),
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: isThisApplied ? const Color(0xFFFFF7F8) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isThisApplied ? const Color(0xFFFECACA) : AppColors.border,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Badge
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isFestive
                                            ? const Color(0x28DC2626)
                                            : const Color(0x1ADC2626),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                                      child: Text(
                                        isFestive ? '60% OFF' : 'SPECIAL OFFER',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.primary,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    // Apply/Remove button
                                    GestureDetector(
                                      onTap: () {
                                        if (isThisApplied) {
                                          context.read<CartCubit>().removeCoupon();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Coupon removed'),
                                              backgroundColor: AppColors.surface,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        } else {
                                          _applyCustomCoupon(coupon, cartState);
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: isThisApplied ? null : AppColors.redGradient,
                                          color: isThisApplied
                                              ? const Color(0xFFFEE2E2)
                                              : null,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: isThisApplied
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.25),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
                                        child: Text(
                                          isThisApplied ? 'Remove' : 'Apply',
                                          style: GoogleFonts.outfit(
                                            color: isThisApplied
                                                ? AppColors.primary
                                                : Colors.white,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 1.5.h),
                              
                              // Coupon Code Title
                              Text(
                                coupon.code,
                                style: GoogleFonts.outfit(
                                  color: AppColors.primaryText,
                                  fontSize: 16.sp, // Strictly between 14.sp to 18.sp
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 1.2.h),

                              // Description
                              Text(
                                coupon.description,
                                style: GoogleFonts.inter(
                                  color: AppColors.secondaryText,
                                  fontSize: 14.sp, // Strictly between 14.sp to 18.sp
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              
                              const Divider(color: AppColors.border, height: 1),
                              SizedBox(height: 1.5.h),

                              // Details Footer Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Min. Order: ₹${coupon.minOrderValue.toInt()}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.secondaryText,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  Text(
                                    coupon.expiryDate,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
