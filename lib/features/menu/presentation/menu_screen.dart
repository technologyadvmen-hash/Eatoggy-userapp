import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../home/data/models/restaurant_model.dart';
import '../cubit/menu_cubit.dart';
import '../cubit/menu_state.dart';

class _MenuOfferBanner {
  final String tag;
  final Color tagBg;
  final Color tagColor;
  final String title;
  final String subtitle;
  final String couponCode;

  const _MenuOfferBanner({
    required this.tag,
    required this.tagBg,
    required this.tagColor,
    required this.title,
    required this.subtitle,
    required this.couponCode,
  });
}

class MenuScreen extends StatefulWidget {
  final dynamic initialRestaurant;

  const MenuScreen({super.key, this.initialRestaurant});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final PageController _offerPageController;
  Timer? _offerTimer;
  int _currentOfferIndex = 0;

  static const List<_MenuOfferBanner> _sampleOffers = [
    _MenuOfferBanner(
      tag: 'VISA',
      tagBg: Color(0xFFEFF6FF),
      tagColor: Color(0xFF1D4ED8),
      title: 'Flat ₹150 OFF with Visa Platinum',
      subtitle: 'Use code VISAPLATINUM on orders ₹499+',
      couponCode: 'VISAPLATINUM',
    ),
    _MenuOfferBanner(
      tag: 'FLAT 20%',
      tagBg: Color(0xFFFEF2F2),
      tagColor: Color(0xFFDC2626),
      title: 'Flat 20% OFF up to ₹120',
      subtitle: 'Use code EATOGGY20 on all Chef Specials',
      couponCode: 'EATOGGY20',
    ),
    _MenuOfferBanner(
      tag: 'UPI CASH',
      tagBg: Color(0xFFECFDF5),
      tagColor: Color(0xFF059669),
      title: '₹75 Instant Cashback via UPI',
      subtitle: 'Pay with GPay, PhonePe, Paytm or Cred',
      couponCode: 'INSTANTUPI',
    ),
    _MenuOfferBanner(
      tag: 'FREE DEL',
      tagBg: Color(0xFFFFFBEB),
      tagColor: Color(0xFFD97706),
      title: 'Free Express Hot-Case Delivery',
      subtitle: 'Use code FREEDEL | Zero delivery fee',
      couponCode: 'FREEDEL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _offerPageController = PageController();
    _startOfferTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialRestaurant();
    });
  }

  void _startOfferTimer() {
    _offerTimer?.cancel();
    _offerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_offerPageController.hasClients) {
        final nextPage = (_currentOfferIndex + 1) % _sampleOffers.length;
        _offerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRestaurant != oldWidget.initialRestaurant && widget.initialRestaurant != null) {
      _applyInitialRestaurant();
    }
  }

  void _applyInitialRestaurant() {
    if (widget.initialRestaurant == null) return;
    if (widget.initialRestaurant is RestaurantModel) {
      final r = widget.initialRestaurant as RestaurantModel;
      context.read<MenuCubit>().loadMenu(
            restaurantId: r.id,
            initialRestaurantName: r.name,
            initialLocation: r.city,
            initialCuisine: r.cuisine,
            initialIsPureVeg: r.isPureVeg,
            initialRating: r.rating,
            initialDeliveryTime: r.deliveryTime,
            initialRatingCount: r.ratingCount,
          );
    } else if (widget.initialRestaurant is Map) {
      final map = widget.initialRestaurant as Map;
      context.read<MenuCubit>().loadMenu(
            restaurantId: map['id']?.toString() ?? map['_id']?.toString(),
            initialRestaurantName:
                map['name']?.toString() ?? map['restaurantName']?.toString(),
            initialLocation:
                map['city']?.toString() ?? map['location']?.toString(),
            initialCuisine: map['cuisine']?.toString(),
          );
    } else if (widget.initialRestaurant is String) {
      context.read<MenuCubit>().loadMenu(
            restaurantId: widget.initialRestaurant as String,
          );
    }
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerPageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, state) {
            return BlocBuilder<CartCubit, CartState>(
              builder: (context, cartState) {
                final hasCartItems = cartState.items.isNotEmpty;
                final cartTotalCount = cartState.items.fold<int>(
                  0,
                  (sum, item) => sum + item.quantity,
                );

                return Stack(
                  children: [
                    // Main Scrollable Menu Content
                    RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        await context.read<MenuCubit>().loadMenu();
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: hasCartItems ? 16.h : 10.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Top Action Navigation Bar
                            _buildTopBar(context),

                            // 2. Hero Restaurant Card
                            _buildRestaurantHeroCard(context, state),

                            SizedBox(height: 2.h),

                            // 3. Search Bar
                            _buildSearchBar(context, state),

                            SizedBox(height: 1.8.h),

                            // 4. Quick Filter Chips Row (Pure Veg, EatRight, 4.0+, Bestseller)
                            _buildFilterChips(context, state),

                            SizedBox(height: 1.5.h),

                            // 5. Category Pills Row
                            _buildCategoryChips(context, state),

                            SizedBox(height: 2.5.h),

                            // 6. Top Picks Horizontal Carousel (shown when searching is inactive or matches)
                            if (state.topPicks.isNotEmpty &&
                                state.searchQuery.isEmpty &&
                                (state.selectedCategory == 'All' ||
                                    state.selectedCategory == 'Top Picks'))
                              _buildTopPicksSection(context, state, cartState),

                            SizedBox(height: 2.5.h),

                            // 7. Recommended / Categorized Menu List
                            _buildCategorizedMenuList(
                                context, state, cartState),
                          ],
                        ),
                      ),
                    ),

                    // 8. Floating "ITEMS" Button (Bottom Right)
                    Positioned(
                      bottom: hasCartItems ? 10.h : 3.h,
                      right: 4.w,
                      child: _buildFloatingItemsButton(context, state),
                    ),

                    // 9. Floating Cart Bottom Bar
                    if (hasCartItems)
                      Positioned(
                        bottom: 1.5.h,
                        left: 4.w,
                        right: 4.w,
                        child: _buildCartSummaryBar(
                          context,
                          cartState,
                          cartTotalCount,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 1. Top Bar with back, group share, and more actions
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 10.5.w,
              height: 10.5.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.primaryText,
                size: 20,
              ),
            ),
          ),

          // Right Action Icons
          GestureDetector(
            onTap: () => _showRestaurantInfoModal(context),
            child: Container(
              width: 10.5.w,
              height: 10.5.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.primaryText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Hero Restaurant Card matching user's reference screenshot
  Widget _buildRestaurantHeroCard(BuildContext context, MenuState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Inner Elevated Restaurant Information Card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pure Veg / Gourmet Badge
                Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: state.isPureVegRestaurant
                          ? const Color(0xFF22C55E)
                          : AppColors.primary,
                      size: 13.sp,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      state.isPureVegRestaurant
                          ? 'Pure Veg'
                          : 'The Royal Menu',
                      style: GoogleFonts.outfit(
                        color: state.isPureVegRestaurant
                            ? const Color(0xFF22C55E)
                            : AppColors.primary,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.2.h),

                // Restaurant Title & Rating Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Restaurant Name and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.restaurantName,
                            style: GoogleFonts.outfit(
                              color: AppColors.primaryText,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Text(
                                '${state.deliveryTime}  |  ${state.restaurantLocation}',
                                style: GoogleFonts.inter(
                                  color: AppColors.secondaryText,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 10),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Hygiene Verified',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF047857),
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 3.w),

                    // Rating Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.8.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F6636),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${state.restaurantRating}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 0.4.h),
                        Text(
                          state.ratingCount,
                          style: GoogleFonts.inter(
                            color: AppColors.secondaryText,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Thin divider line
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.6.h),
                  child: const Divider(
                    color: AppColors.border,
                    height: 1,
                    thickness: 1,
                  ),
                ),

                // Offers Strip / Animated 4-Banner Carousel Box
                Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated Swiping / Auto-scrolling Banners
                      Expanded(
                        child: PageView.builder(
                          controller: _offerPageController,
                          itemCount: _sampleOffers.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentOfferIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final offer = _sampleOffers[index];
                            return GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: offer.couponCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon code "${offer.couponCode}" copied!'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: const Color(0xFF1C1917),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  // Discount Badge Icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: offer.tagBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: offer.tagColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      offer.tag,
                                      style: GoogleFonts.outfit(
                                        color: offer.tagColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10.sp,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.5.w),

                                  // Offer text details
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offer.title,
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primaryText,
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          offer.subtitle,
                                          style: GoogleFonts.inter(
                                            color: AppColors.secondaryText,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(width: 2.w),

                      // Animated Page Indicator Dots & Dynamic Fraction
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_currentOfferIndex + 1}/${_sampleOffers.length}',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_sampleOffers.length, (dotIdx) {
                              final isActive = dotIdx == _currentOfferIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(left: 3),
                                width: isActive ? 10 : 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Free delivery banner strip underneath
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Free delivery on orders above ₹${state.freeDeliveryAbove}',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.2.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'one',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Search Bar for real-time dish filtering
  Widget _buildSearchBar(BuildContext context, MenuState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        height: 6.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 3.5.w),
            Icon(
              Icons.search,
              color: AppColors.secondaryText,
              size: 16.sp,
            ),
            SizedBox(width: 2.5.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  color: AppColors.primaryText,
                  fontSize: 13.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for dishes',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.secondaryText,
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (text) {
                  context.read<MenuCubit>().setSearchQuery(text);
                  setState(() {});
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.primaryText,
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  context.read<MenuCubit>().setSearchQuery('');
                  setState(() {});
                },
              )
            else ...[
              Container(
                height: 3.h,
                width: 1,
                color: AppColors.surface,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Icon(
                  Icons.mic,
                  color: AppColors.primary,
                  size: 16.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. Horizontal Quick Filter Chips Row (Pure Veg, EatRight, Ratings 4.0+, Bestseller)
  Widget _buildFilterChips(BuildContext context, MenuState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          // Pure Veg Chip
          _buildFilterChip(
            iconWidget: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: state.isVegOnly
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF22C55E),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
            label: 'Pure Veg',
            isSelected: state.isVegOnly,
            selectedColor: const Color(0xFF22C55E),
            onTap: () => context.read<MenuCubit>().toggleVegOnly(),
          ),
          SizedBox(width: 2.5.w),

          // EatRight Chip
          _buildFilterChip(
            iconWidget: Icon(
              Icons.favorite_rounded,
              color: state.isEatRightOnly
                  ? AppColors.primary
                  : AppColors.secondaryText,
              size: 14,
            ),
            label: 'EatRight',
            isSelected: state.isEatRightOnly,
            selectedColor: AppColors.primary,
            onTap: () => context.read<MenuCubit>().toggleEatRight(),
          ),
          SizedBox(width: 2.5.w),

          // Ratings 4.0+ Chip
          _buildFilterChip(
            iconWidget: Icon(
              Icons.star_rounded,
              color: state.isRatings4Plus
                  ? AppColors.primary
                  : Colors.amber[700],
              size: 16,
            ),
            label: 'Ratings 4.0+',
            isSelected: state.isRatings4Plus,
            selectedColor: AppColors.primary,
            onTap: () => context.read<MenuCubit>().toggleRatings4Plus(),
          ),
          SizedBox(width: 2.5.w),

          // Bestseller Chip
          _buildFilterChip(
            iconWidget: Icon(
              Icons.local_fire_department_rounded,
              color: state.isBestsellerOnly
                  ? AppColors.primary
                  : AppColors.secondaryText,
              size: 15,
            ),
            label: 'Bestseller',
            isSelected: state.isBestsellerOnly,
            selectedColor: AppColors.primary,
            onTap: () => context.read<MenuCubit>().toggleBestseller(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    Widget? iconWidget,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.9.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: isSelected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              iconWidget,
              SizedBox(width: 1.8.w),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? selectedColor : AppColors.primaryText,
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 1.5.w),
              Icon(
                Icons.check,
                color: selectedColor,
                size: 13,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5. Category selection row
  Widget _buildCategoryChips(BuildContext context, MenuState state) {
    return SizedBox(
      height: 4.6.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final cat = state.categories[index];
          final isSelected = state.selectedCategory == cat;
          return GestureDetector(
            onTap: () => context.read<MenuCubit>().selectCategory(cat),
            child: Container(
              margin: EdgeInsets.only(right: 2.2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: 1.1,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 6. Top Picks Horizontal Carousel matching reference image
  Widget _buildTopPicksSection(
    BuildContext context,
    MenuState state,
    CartState cartState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Top Picks',
            style: GoogleFonts.outfit(
              color: AppColors.primaryText,
              fontSize: 16.5.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 1.4.h),
        SizedBox(
          height: 23.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: state.topPicks.length,
            itemBuilder: (context, index) {
              final food = state.topPicks[index];
              final cartItem = cartState.items.cast<CartItem?>().firstWhere(
                    (it) => it?.food.id == food.id,
                    orElse: () => null,
                  );
              final qty = cartItem?.quantity ?? 0;

              return GestureDetector(
                onTap: () => context.push('/food-detail', extra: food),
                child: Container(
                  width: 44.w,
                  margin: EdgeInsets.only(right: 3.5.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Food Image
                        _buildFoodImage(food),

                        // Gradient overlay from bottom for text legibility
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.95),
                              ],
                              stops: const [0.35, 0.65, 1.0],
                            ),
                          ),
                        ),

                        // Content details pinned to bottom
                        Positioned(
                          left: 3.w,
                          right: 3.w,
                          bottom: 1.2.h,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Veg / Non-Veg Icon
                              _buildVegBadge(food.isVeg),
                              SizedBox(height: 0.5.h),

                              // Food Name
                              Text(
                                food.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.6.h),

                              // Price and ADD button row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${food.price.toInt()}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Overlaid ADD / Stepper Button
                                  _buildTopPickAddButton(context, food, qty),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADD Button for Top Picks cards
  Widget _buildTopPickAddButton(
    BuildContext context,
    FoodItem food,
    int qty,
  ) {
    if (qty > 0) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                context.read<CartCubit>().updateQuantity(food, qty - 1);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(
                  Icons.remove,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              '$qty',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11.5.sp,
              ),
            ),
            InkWell(
              onTap: () {
                context.read<CartCubit>().addToCart(food);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(
                  Icons.add,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        context.read<CartCubit>().addToCart(food);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              '${food.name} Added!',
              style: const TextStyle(color: AppColors.primaryText),
            ),
            duration: const Duration(milliseconds: 900),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF22C55E),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'ADD',
          style: GoogleFonts.outfit(
            color: const Color(0xFF15803D),
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // 7. Categorized Menu List matching reference screenshot
  Widget _buildCategorizedMenuList(
    BuildContext context,
    MenuState state,
    CartState cartState,
  ) {
    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: const CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (state.meals.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 28.sp,
                color: AppColors.secondaryText,
              ),
              SizedBox(height: 1.5.h),
              Text(
                'No dishes match your active filter.',
                style: GoogleFonts.outfit(
                  color: AppColors.secondaryText,
                  fontSize: 13.5.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final headerTitle = state.selectedCategory == 'All'
        ? 'Recommended (${state.meals.length})'
        : '${state.selectedCategory} (${state.meals.length})';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header Row with dropdown icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headerTitle,
                style: GoogleFonts.outfit(
                  color: AppColors.primaryText,
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryText,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 1.2.h),

          // Dishes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.meals.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.border,
              height: 28,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final food = state.meals[index];
              final cartItem = cartState.items.cast<CartItem?>().firstWhere(
                    (it) => it?.food.id == food.id,
                    orElse: () => null,
                  );
              final qty = cartItem?.quantity ?? 0;

              return _buildRecommendedDishRow(context, food, qty);
            },
          ),
        ],
      ),
    );
  }

  // Individual dish item in the recommended list
  Widget _buildRecommendedDishRow(
    BuildContext context,
    FoodItem food,
    int qty,
  ) {
    return GestureDetector(
      onTap: () => context.push('/food-detail', extra: food),
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg / Non-Veg Icon
                  _buildVegBadge(food.isVeg),
                  SizedBox(height: 0.6.h),

                  // Food Name
                  Text(
                    food.name,
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryText,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),

                  // Price
                  Text(
                    '₹${food.price.toInt()}',
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryText,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),

                  // Rating pill
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: const Color(0xFF22C55E),
                        size: 13.sp,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${food.rating} (80+)',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E),
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.6.h),

                  // Description
                  Text(
                    food.description,
                    style: GoogleFonts.inter(
                      color: AppColors.secondaryText,
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 3.5.w),

            // Right Column: Image with overlapping ADD button and customisable caption
            Column(
              children: [
                SizedBox(
                  width: 29.w,
                  height: 31.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 29.w,
                          height: 25.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _buildFoodImage(food),
                        ),
                      ),

                      // Overlapping ADD / Stepper Button at bottom of thumbnail
                      Positioned(
                        bottom: 0,
                        child: _buildRowAddButton(context, food, qty),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  'Customisable',
                  style: GoogleFonts.inter(
                    color: AppColors.secondaryText,
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Row Add / Stepper Button (white with green text)
  Widget _buildRowAddButton(
    BuildContext context,
    FoodItem food,
    int qty,
  ) {
    if (qty > 0) {
      return Container(
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                context.read<CartCubit>().updateQuantity(food, qty - 1);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  Icons.remove,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              '$qty',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
            InkWell(
              onTap: () {
                context.read<CartCubit>().addToCart(food);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        context.read<CartCubit>().addToCart(food);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              '${food.name} Added to Cart!',
              style: const TextStyle(color: AppColors.primaryText),
            ),
            duration: const Duration(milliseconds: 900),
          ),
        );
      },
      child: Container(
        height: 3.8.h,
        padding: EdgeInsets.symmetric(horizontal: 5.5.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryText,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'ADD',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F6636),
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // 8. Floating "ITEMS" Action Button (Bottom Right)
  Widget _buildFloatingItemsButton(BuildContext context, MenuState state) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showItemsCategorySheet(context, state);
      },
      child: Container(
        width: 16.w,
        height: 16.w,
        decoration: BoxDecoration(
          color: const Color(0xFF11110F),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 21,
            ),
            SizedBox(height: 0.2.h),
            Text(
              'ITEMS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 9.sp,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 9. Floating Cart Bottom Bar
  Widget _buildCartSummaryBar(
    BuildContext context,
    CartState cartState,
    int cartTotalCount,
  ) {
    return GestureDetector(
      onTap: () => context.push('/cart'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.5.w, vertical: 1.4.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1917),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary,
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Cart Count & Amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$cartTotalCount ${cartTotalCount == 1 ? "ITEM" : "ITEMS"} ADDED',
                      style: GoogleFonts.inter(
                        color: AppColors.secondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹${cartState.subtotal.toInt()}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right "View Cart →" Button
            Row(
              children: [
                Text(
                  'View Cart',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 1.w),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal Category Sheet opened by the floating "ITEMS" button
  void _showItemsCategorySheet(BuildContext context, MenuState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: 65.h),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 1.5),
              left: BorderSide(color: AppColors.surface, width: 1),
              right: BorderSide(color: AppColors.surface, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 12.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu Categories',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primaryText,
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.allMeals.length} Dishes',
                    style: GoogleFonts.inter(
                      color: AppColors.secondaryText,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final cat = state.categories[index];
                    final isSelected = state.selectedCategory == cat;
                    final count = cat == 'All'
                        ? state.allMeals.length
                        : state.allMeals.where((m) => m.category == cat).length;

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0.5.h,
                        horizontal: 2.w,
                      ),
                      title: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primaryText,
                          fontSize: 13.5.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w,
                          vertical: 0.4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentLight
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.secondaryText,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.read<MenuCubit>().selectCategory(cat);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Restaurant details modal
  void _showRestaurantInfoModal(BuildContext context) {
    final state = context.read<MenuCubit>().state;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 12.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3932),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                state.restaurantName,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primaryText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                '${state.restaurantCuisine} • ${state.restaurantLocation}',
                style: GoogleFonts.inter(
                  color: AppColors.secondaryText,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF48C765),
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'FSSAI Certified Royal Kitchen',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF48C765),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Delivery ETA: ${state.deliveryTime}',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryText,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
            ],
          ),
        );
      },
    );
  }

  // Veg / Non-Veg square badge
  Widget _buildVegBadge(bool isVeg) {
    final color = isVeg ? const Color(0xFF22C55E) : const Color(0xFFE53935);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.3),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  // Food image renderer with fallback handling
  Widget _buildFoodImage(FoodItem food) {
    Widget imageWidget;
    if (food.imageUrl.startsWith('http') &&
        !food.imageUrl.contains('pub-advmenngo.r2.dev')) {
      imageWidget = Image.network(
        food.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          food.fallbackImageAsset,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Image.asset(
        food.imageUrl.isNotEmpty ? food.imageUrl : food.fallbackImageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          food.fallbackImageAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    return Hero(
      tag: 'food_dish_${food.id}',
      child: imageWidget,
    );
  }
}
