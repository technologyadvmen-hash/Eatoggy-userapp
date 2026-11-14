import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';
import '../cubit/cart_cubit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartCubit>().fetchCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            // -----------------------------
            // Loading State
            // -----------------------------
            if (state.isLoading && state.items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            // -----------------------------
            // Empty Cart State
            // -----------------------------
            if (state.items.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () {
                      return context.read<CartCubit>().fetchCart();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.shopping_basket_outlined,
                                      size: 46.sp,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'Your Box is Empty',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryText,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 1.2.h),
                                Text(
                                  'Add delicious home-cooked meals to your box.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.secondaryText,
                                    fontSize: 14.5.sp,
                                  ),
                                ),
                                SizedBox(height: 3.5.h),
                                GestureDetector(
                                  onTap: () {
                                    context.go('/menu');
                                  },
                                  child: Container(
                                    width: 52.w,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Explore Menu',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // -----------------------------
            // Bill Calculations
            // -----------------------------
            final double subtotal = state.subtotal;
            final double discount = state.discountAmount;

            final double grandTotal = subtotal - discount;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () {
                return context.read<CartCubit>().fetchCart();
              },
              child: Stack(
                children: [
                  // =========================================================
                  // SCROLLABLE CONTENT
                  // =========================================================
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 5.w,
                      right: 5.w,
                      top: 2.h,
                      bottom: 22.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -----------------------------
                        // Title Header
                        // -----------------------------
                        Row(
                          children: [
                            if (Navigator.of(context).canPop()) ...[
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
                            ],
                            Text(
                              'Your Box',
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryText,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // =================================================
                        // CART ITEMS
                        // =================================================
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];

                            return Container(
                              margin: EdgeInsets.only(bottom: 2.h),
                              padding: EdgeInsets.all(3.5.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border,
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // -----------------------------
                                  // Food Image
                                  // -----------------------------
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildFoodImage(item),
                                  ),

                                  SizedBox(width: 4.w),

                                  // -----------------------------
                                  // Food Details
                                  // -----------------------------
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.food.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  color: AppColors.primaryText,
                                                  fontSize: 15.5.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                context
                                                    .read<CartCubit>()
                                                    .removeFromCart(item);
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(left: 2.w),
                                                child: Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: const Color(0xFFEF4444),
                                                  size: 17.5.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 0.4.h),

                                        Text(
                                          item.food.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: AppColors.secondaryText,
                                            fontSize: 13.5.sp,
                                          ),
                                        ),

                                        SizedBox(height: 1.2.h),

                                        // -----------------------------
                                        // Price + Quantity
                                        // -----------------------------
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${item.food.price.toInt()}',
                                              style: GoogleFonts.outfit(
                                                color: AppColors.primary,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            // Quantity Selector
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                border: Border.all(
                                                  color: AppColors.border,
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 2.2.w,
                                                      vertical: 0.6.h,
                                                    ),
                                                    icon: Icon(
                                                      item.quantity == 1
                                                          ? Icons.delete_outline_rounded
                                                          : Icons.remove_rounded,
                                                      color: item.quantity == 1
                                                          ? const Color(0xFFEF4444)
                                                          : AppColors.secondaryText,
                                                      size: 17.5.sp,
                                                    ),
                                                    onPressed: () {
                                                      context
                                                          .read<CartCubit>()
                                                          .updateQuantity(
                                                            item,
                                                            item.quantity - 1,
                                                          );
                                                    },
                                                  ),

                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 2.w,
                                                    ),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style:
                                                          GoogleFonts.outfit(
                                                        color: AppColors.primaryText,
                                                        fontSize: 17.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),

                                                  IconButton(
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 2.2.w,
                                                      vertical: 0.6.h,
                                                    ),
                                                    icon: Icon(
                                                      Icons.add_rounded,
                                                      color: AppColors.primary,
                                                      size: 17.5.sp,
                                                    ),
                                                    onPressed: () {
                                                      context
                                                          .read<CartCubit>()
                                                          .updateQuantity(
                                                            item,
                                                            item.quantity + 1,
                                                          );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 2.h),

                        // =================================================
                        // APPLY COUPON / CHECK OFFER BANNER
                        // Matches c14-cart.svg red gradient offer bar
                        // =================================================
                        GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.offers);
                          },
                          child: Container(
                            height: 6.5.h,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              gradient: AppColors.redGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),

                                SizedBox(width: 3.w),

                                Expanded(
                                  child: Text(
                                    state.appliedCoupon != null
                                        ? '${state.appliedCoupon!.code} Applied (₹${discount.toInt()} Saved)'
                                        : 'Check Offer & Apply Coupon',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),

                                // Coupon Remove / Check Offer CTA
                                if (state.appliedCoupon != null)
                                  GestureDetector(
                                    onTap: () {
                                      context
                                          .read<CartCubit>()
                                          .removeCoupon();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Remove',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Text(
                                        'Check Offer',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 1.w),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // =================================================
                        // BILL SUMMARY
                        // Matches c14-cart.svg LUXURY BILL SUMMARY
                        // =================================================
                        Text(
                          'LUXURY BILL SUMMARY',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),

                        SizedBox(height: 1.5.h),

                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
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
                            children: [
                              _buildSummaryItem(
                                'Item Subtotal',
                                '₹${subtotal.toInt()}',
                              ),
                              _buildSummaryItem(
                                'Insulated Hot-Case Delivery',
                                'FREE',
                              ),
                              _buildSummaryItem(
                                'Surcharge & Taxes',
                                '₹0.00',
                              ),

                              if (discount > 0)
                                _buildSummaryItem(
                                  'Coupon Discount',
                                  '-₹${discount.toInt()}',
                                  isDiscount: true,
                                ),

                              const Divider(
                                color: AppColors.border,
                                height: 24,
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Grand Total',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryText,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${grandTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Space for fixed bottom checkout panel
                        SizedBox(height: 14.h),
                      ],
                    ),
                  ),

                  // =========================================================
                  // FIXED BOTTOM CHECKOUT PANEL
                  // =========================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          top: BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // -----------------------------
                          // Total
                          // -----------------------------
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TO PAY',
                                style: GoogleFonts.outfit(
                                  color: AppColors.secondaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                '₹${grandTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontSize: 19.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 5.w),

                          // -----------------------------
                          // Checkout Button
                          // -----------------------------
                          Expanded(
                            child: SpeedAnimatedButton(
                              text: 'Proceed to Checkout',
                              height: 52,
                              borderRadius: BorderRadius.circular(16),
                              textStyle: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              suffixIcon: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              onPressed: () {
                                context.push('/checkout');
                              },
                            ),
                          ),
                        ],
                      ),
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

  // =========================================================
  // FOOD IMAGE
  // =========================================================

  Widget _buildFoodImage(dynamic item) {
    final String imageUrl = item.food.imageUrl;
    final String fallbackImage = item.food.fallbackImageAsset;

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 16.w,
        height: 16.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackImage,
            width: 16.w,
            height: 16.w,
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image.asset(
      imageUrl.isNotEmpty ? imageUrl : fallbackImage,
      width: 16.w,
      height: 16.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          fallbackImage,
          width: 16.w,
          height: 16.w,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // =========================================================
  // BILL SUMMARY ITEM
  // =========================================================

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.secondaryText,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: isDiscount
                  ? const Color(0xFF16A34A)
                  : AppColors.primaryText,
              fontSize: 14.5.sp,
              fontWeight: isDiscount
                  ? FontWeight.bold
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
