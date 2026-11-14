import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import '../cubit/home_cubit.dart';
import '../data/models/collection_model.dart';
import '../data/models/restaurant_model.dart';
import '../../../widgets/custom_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _hasShownPopup = false;
  String? _activeMindCategory;
  bool _isVegOnly = false;
  final int _activeBannerIndex = 0;
  String _currentAddress = 'NX ONE, Noida, 201301, U';

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadDashboard();
    context.read<CartCubit>().fetchCart();
    context.read<SubscriptionCubit>().loadMySubscriptions();
    _loadSavedLocation();

    if (!_hasShownPopup) {
      _hasShownPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTiffinPopup();
      });
    }
  }

  void _showTiffinPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.secondaryText),
                  ),
                ),
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Royal Tiffin Subscription',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enjoy authentic home-cooked luxury meals delivered fresh to your door every day.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SpeedAnimatedButton(
                  text: 'Explore Plans',
                  height: 50,
                  borderRadius: BorderRadius.circular(14),
                  textStyle: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/subscription');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferencesService.getInstance();
    final address = prefs.getString(AppKeys.currentAddress);
    if (address != null && address.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await Future.wait([
                  context.read<HomeCubit>().loadDashboard(),
                  context.read<CartCubit>().fetchCart(),
                  context.read<SubscriptionCubit>().loadMySubscriptions(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Top Header Bar (Logo, Location, Notification) ──────
                    _buildTopHeader(),

                    SizedBox(height: 1.2.h),

                    // ── 2. Search Box with Integrated VEG Toggle ──────────────
                    _buildSearchBarWithVeg(),

                    SizedBox(height: 1.8.h),

                    // ── 3. Festive Hero Banner ("Taste the Good Life") ────────
                    _buildHeroBanner(state),

                    SizedBox(height: 2.h),

                    // ── 5. Special Offer Cards (Flat ₹200 OFF, Free Treat...) ──
                    _buildOfferCards(),

                    SizedBox(height: 2.2.h),

                    // ── 5.5. Active Subscription Strip (if subscribed) ────────
                    _buildActiveSubscriptionStrip(),

                    // ── 6. Circular Food Categories ("What's on your Mind?") ──
                    _buildCategoriesSection(state),

                    // ── 6.5. Dropdown Dishes Slider (Between Categories & Restaurants) ──
                    if (_activeMindCategory != null) ...[
                      SizedBox(height: 1.6.h),
                      _buildMindCategoryDropdownSlider(state),
                    ],

                    SizedBox(height: 2.4.h),

                    // ── 7. Popular Restaurants Section ────────────────────────
                    _buildPopularRestaurantsSection(state),

                    SizedBox(height: 3.h),

                    // ── 8. Top Rated Dishes Section ───────────────────────────
                    _buildTopRatedDishesSection(state),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP HEADER (Logo Badge, Location, Notifications Bell)
  // ===========================================================================
  Widget _buildTopHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Eatoggy App Logo Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/eatoggy_speed_logo.png',
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(width: 2.5.w),

          // Location Selector
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await context.push('/select-location');
                _loadSavedLocation();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 1.5.w),
                  Flexible(
                    child: Text(
                      _currentAddress,
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryText,
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1C1C1C),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 2.5.w),

          // Notification Bell in Round Card with Red Badge
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF44403C),
                    size: 20,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4722),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Optional Cart Badge if cart has items
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState.items.fold(0, (sum, item) => sum + item.quantity);
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(left: 2.w),
                child: GestureDetector(
                  onTap: () => context.push('/cart'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SEARCH BOX + CLEARLY NAMED VEG TOGGLE
  // ===========================================================================
  Widget _buildSearchBarWithVeg() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/search'),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search for restaurants, dishes & cuisines...',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF78716C),
                          fontSize: 13.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // VEG Mode Switch Pill - Clearly labeled with green veg icon and smooth toggle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isVegOnly = !_isVegOnly;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _isVegOnly ? const Color(0xFFDCFCE7) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isVegOnly ? const Color(0xFF16A34A) : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Green Veg square icon
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFF16A34A), width: 1.3),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'VEG',
                    style: GoogleFonts.outfit(
                      color: _isVegOnly ? const Color(0xFF16A34A) : AppColors.primaryText,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Animated switch thumb
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 16,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isVegOnly ? const Color(0xFF22C55E) : const Color(0xFFD6D3D1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: _isVegOnly ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. HERO BANNER ("Taste the Good Life")
  // ===========================================================================
  Widget _buildHeroBanner(HomeState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE8E8), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  // Left Content Column (Blush Pink `#FFF1F2`)
                  Expanded(
                    flex: 11,
                    child: Container(
                      color: const Color(0xFFFFF1F2),
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DELICIOUS FOOD',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF78716C),
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Taste the\n',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF1C1917),
                                        fontSize: 21.sp,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Good Life',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFBE0000),
                                        fontSize: 23.sp,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Get up to 20% OFF on your favourite meals',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF57534E),
                                  fontSize: 11.5.sp,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.menu),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Order Now',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Image Column with Circular Discount Badge
                  Expanded(
                    flex: 9,
                    child: Stack(
                      children: [
                        SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/home_svg/hero_biryani.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/biryani.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Circular "UP TO 20% OFF" Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF942E1F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'UP TO',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '20%',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      height: 0.95,
                                    ),
                                  ),
                                  Text(
                                    'OFF',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isActive = _activeBannerIndex == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : const Color(0xFFD6D3D1),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. SPECIAL OFFER CARDS (Horizontal Scroll)
  // ===========================================================================
  Widget _buildOfferCards() {
    final offers = [
      {
        'title': 'Flat ₹200\nOFF & More',
        'color': const Color(0xFFFFECEE),
        'textColor': const Color(0xFF991B1B),
        'borderColor': const Color(0xFFFECDD3),
        'icon': Icons.currency_rupee_rounded,
      },
      {
        'title': 'Get A Free\nTreat',
        'color': const Color(0xFFE6F7F0),
        'textColor': const Color(0xFF065F46),
        'borderColor': const Color(0xFFA7F3D0),
        'image': 'assets/home_svg/offer_treat.jpg',
      },
      {
        'title': 'Meals\nAt ₹99',
        'color': const Color(0xFFFDEFD7),
        'textColor': const Color(0xFF9A3412),
        'borderColor': const Color(0xFFFED7AA),
        'icon': Icons.restaurant_menu_rounded,
      },
    ];

    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return GestureDetector(
            onTap: () => context.push('/offers'),
            child: Container(
              width: 135,
              margin: EdgeInsets.only(right: 3.w),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: offer['color'] as Color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: offer['borderColor'] as Color, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      offer['title'] as String,
                      style: GoogleFonts.outfit(
                        color: offer['textColor'] as Color,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (offer.containsKey('image'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        offer['image'] as String,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fastfood,
                          size: 24,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (offer['textColor'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        offer['icon'] as IconData,
                        size: 16,
                        color: offer['textColor'] as Color,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5.5. ACTIVE SUBSCRIPTION STRIP (if user is subscribed)
  // ===========================================================================
  Widget _buildActiveSubscriptionStrip() {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, subState) {
        final activeSub = subState.activeSubscription;
        if (activeSub == null) return const SizedBox.shrink();

        final isActive = activeSub.status.toUpperCase() == 'ACTIVE';
        return Padding(
          padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 2.h),
          child: Container(
            padding: EdgeInsets.all(3.5.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lunch_dining, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeSub.plan.name,
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryText,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${activeSub.remainingMeals} of ${activeSub.plan.totalMeals} meals remaining',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF78716C),
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/my-subscription'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Manage',
                      style: GoogleFonts.inter(
                        color: isActive ? const Color(0xFF16A34A) : AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 6. CIRCULAR FOOD CATEGORIES ("What's on your Mind?")
  // ===========================================================================
  Widget _buildCategoriesSection(HomeState state) {
    final categories = state.collections.isNotEmpty
        ? state.collections
        : CollectionModel.defaultCollections();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Heading: "What's on your Mind?" with Cuisine Dropdown Menu
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "What's on your Mind?",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1C1917),
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Dropdown Button Selector
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _activeMindCategory != null ? const Color(0xFFFEE2E2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _activeMindCategory != null ? AppColors.primary : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _activeMindCategory,
                    hint: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cuisines',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF78716C),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF78716C)),
                      ],
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                    isDense: true,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.name,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _activeMindCategory = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.5.h),

        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _activeMindCategory?.toLowerCase() == cat.name.toLowerCase();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_activeMindCategory?.toLowerCase() == cat.name.toLowerCase()) {
                      _activeMindCategory = null; // Toggle close
                    } else {
                      _activeMindCategory = cat.name; // Open slider for this category
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 4.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2.5 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: cat.displayImageUrl.startsWith('http')
                              ? Image.network(
                                  cat.displayImageUrl,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/biryani.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  cat.displayImageUrl,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/biryani.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: GoogleFonts.inter(
                          color: isSelected ? AppColors.primary : const Color(0xFF1C1917),
                          fontSize: 12.5.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6.5. DROPDOWN DISHES SLIDER (Triggered by "What's on your Mind?")
  // ===========================================================================
  Widget _buildMindCategoryDropdownSlider(HomeState state) {
    if (_activeMindCategory == null) return const SizedBox.shrink();

    final categoryDishes = _getDishesForCategory(_activeMindCategory!, state);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3ECE4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown Header Row: Selected category title & Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Special $_activeMindCategory Dishes',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1C1917),
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeMindCategory = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7E5E4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF57534E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Slider of Dishes
          SizedBox(
            height: 220,
            child: categoryDishes.isEmpty
              ? Center(
                  child: Text(
                    'No dishes found for $_activeMindCategory',
                    style: GoogleFonts.inter(
                      color: AppColors.secondaryText,
                      fontSize: 13.sp,
                    ),
                  ),
                )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: categoryDishes.length,
                    itemBuilder: (context, index) {
                      final dish = categoryDishes[index];
                      return _buildDishCardItem(dish, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Get matching dishes for the selected circular mind category
  List<FoodItem> _getDishesForCategory(String categoryName, HomeState state) {
    final cat = categoryName.toLowerCase().trim();

    final allDishes = <FoodItem>[
      ...state.gourmetCreations.map((g) => g.toFoodItem()),
      ..._canonicalSvgDishes(),
    ];

    final List<FoodItem> fallbackCategoryDishes;
    if (cat.contains('pizza')) {
      fallbackCategoryDishes = const [
        FoodItem(
          id: 'cat_dish_pizza_1',
          name: 'Farmhouse Fresh Veggie Pizza',
          description: 'Loaded with crisp bell peppers, grilled mushrooms, sweet corn, and stringy mozzarella.',
          price: 289,
          imageUrl: 'assets/home_svg/cat_pizza.jpg',
          category: 'Pizza',
          rating: 4.8,
          isVeg: true,
          nutrition: '540 kcal • 18g Protein • 62g Carbs',
          ingredients: ['Bell Peppers', 'Mushrooms', 'Sweet Corn', 'Mozzarella', 'Wheat Crust'],
        ),
        FoodItem(
          id: 'cat_dish_pizza_2',
          name: 'Smoked Chicken & BBQ Pizza',
          description: 'Tender smoked barbecue chicken chunks on a bed of herb-infused tomato reduction.',
          price: 349,
          imageUrl: 'assets/home_svg/cat_pizza.jpg',
          category: 'Pizza',
          rating: 4.9,
          isVeg: false,
          nutrition: '620 kcal • 28g Protein • 58g Carbs',
          ingredients: ['Smoked Chicken', 'BBQ Glaze', 'Onions', 'Mozzarella', 'Herbs'],
        ),
        FoodItem(
          id: 'cat_dish_pizza_3',
          name: 'Double Cheese Margherita',
          description: 'Golden crust topped with rich San Marzano tomato puree and extra mozzarella melt.',
          price: 229,
          imageUrl: 'assets/home_svg/cat_pizza.jpg',
          category: 'Pizza',
          rating: 4.7,
          isVeg: true,
          nutrition: '480 kcal • 16g Protein • 52g Carbs',
          ingredients: ['San Marzano Tomatoes', 'Fresh Mozzarella', 'Basil', 'Extra Virgin Olive Oil'],
        ),
      ];
    } else if (cat.contains('burger')) {
      fallbackCategoryDishes = const [
        FoodItem(
          id: 'cat_dish_burger_1',
          name: 'Crispy Zinger Chicken Burger',
          description: 'Signature crispy fried chicken fillet with spicy mayonnaise and fresh iceberg lettuce.',
          price: 189,
          imageUrl: 'assets/home_svg/cat_burger.jpg',
          category: 'Burgers',
          rating: 4.8,
          isVeg: false,
          nutrition: '510 kcal • 24g Protein • 44g Carbs',
          ingredients: ['Crispy Chicken Fillet', 'Iceberg Lettuce', 'Spicy Mayo', 'Brioche Bun'],
        ),
        FoodItem(
          id: 'cat_dish_burger_2',
          name: 'Veggie Supreme Double Patty',
          description: 'Crispy spiced potato & corn patty layered with chipotle mayo and melted cheddar cheese.',
          price: 149,
          imageUrl: 'assets/home_svg/cat_burger.jpg',
          category: 'Burgers',
          rating: 4.6,
          isVeg: true,
          nutrition: '430 kcal • 12g Protein • 52g Carbs',
          ingredients: ['Potato Corn Patty', 'Cheddar Cheese', 'Chipotle Sauce', 'Sesame Bun'],
        ),
        FoodItem(
          id: 'cat_dish_burger_3',
          name: 'Peri-Peri Paneer Crunch Burger',
          description: 'Tender cottage cheese steak tossed in fiery peri-peri seasoning and toasted brioche buns.',
          price: 179,
          imageUrl: 'assets/home_svg/cat_burger.jpg',
          category: 'Burgers',
          rating: 4.7,
          isVeg: true,
          nutrition: '490 kcal • 20g Protein • 46g Carbs',
          ingredients: ['Paneer Steak', 'Peri-Peri Spice', 'Grilled Onions', 'Brioche Bun'],
        ),
      ];
    } else if (cat.contains('biryani') || cat.contains('rice')) {
      fallbackCategoryDishes = const [
        FoodItem(
          id: 'cat_dish_biryani_1',
          name: 'Hyderabadi Chicken Dum Biryani',
          description: 'Authentic kacchi dum cooked long-grain basmati with succulent bone-in chicken.',
          price: 269,
          imageUrl: 'assets/home_svg/dish_chicken_biryani.jpg',
          category: 'Biryani',
          rating: 4.9,
          isVeg: false,
          nutrition: '580 kcal • 32g Protein • 68g Carbs',
          ingredients: ['Basmati Rice', 'Chicken', 'Dum Spices', 'Saffron', 'Pure Ghee'],
        ),
        FoodItem(
          id: 'cat_dish_biryani_2',
          name: 'Awadhi Shahi Paneer Biryani',
          description: 'Marinated paneer cubes slow cooked with saffron milk and aromatic potli masala.',
          price: 229,
          imageUrl: 'assets/biryani.png',
          category: 'Biryani',
          rating: 4.8,
          isVeg: true,
          nutrition: '520 kcal • 22g Protein • 64g Carbs',
          ingredients: ['Paneer Cubes', 'Basmati Rice', 'Potli Masala', 'Brown Onions', 'Kewra'],
        ),
        FoodItem(
          id: 'cat_dish_biryani_3',
          name: 'Royal Lucknawi Mutton Biryani',
          description: 'Melt-in-mouth tender meat infused with cardamom, kewra, and caramelized onions.',
          price: 389,
          imageUrl: 'assets/biryani.png',
          category: 'Biryani',
          rating: 4.9,
          isVeg: false,
          nutrition: '650 kcal • 38g Protein • 62g Carbs',
          ingredients: ['Tender Mutton', 'Aged Basmati', 'Shahi Masala', 'Cardamom', 'Ghee'],
        ),
      ];
    } else if (cat.contains('chinese') || cat.contains('noodle')) {
      fallbackCategoryDishes = const [
        FoodItem(
          id: 'cat_dish_chinese_1',
          name: 'Schezwan Hakka Noodles',
          description: 'Wok-tossed noodles with shredded vegetables in piquant red schezwan sauce.',
          price: 169,
          imageUrl: 'assets/home_svg/cat_chinese.jpg',
          category: 'Chinese',
          rating: 4.7,
          isVeg: true,
          nutrition: '380 kcal • 10g Protein • 58g Carbs',
          ingredients: ['Hakka Noodles', 'Schezwan Peppers', 'Spring Onions', 'Garlic', 'Sesame'],
        ),
        FoodItem(
          id: 'cat_dish_chinese_2',
          name: 'Veg Manchurian Gravy & Fried Rice',
          description: 'Crispy cabbage & carrot dumplings simmered in ginger soy gravy with aromatic fried rice.',
          price: 199,
          imageUrl: 'assets/home_svg/cat_chinese.jpg',
          category: 'Chinese',
          rating: 4.8,
          isVeg: true,
          nutrition: '440 kcal • 12g Protein • 66g Carbs',
          ingredients: ['Manchurian Balls', 'Soy Sauce', 'Jasmine Rice', 'Celery', 'Ginger'],
        ),
        FoodItem(
          id: 'cat_dish_chinese_3',
          name: 'Chilli Chicken Gravy Bowl',
          description: 'Diced chicken tossed with capsicum, green chillies, and savory dark soy sauce.',
          price: 239,
          imageUrl: 'assets/home_svg/cat_chinese.jpg',
          category: 'Chinese',
          rating: 4.9,
          isVeg: false,
          nutrition: '460 kcal • 28g Protein • 38g Carbs',
          ingredients: ['Diced Chicken', 'Green Chillies', 'Capsicum', 'Dark Soy', 'Garlic'],
        ),
      ];
    } else if (cat.contains('south indian') || cat.contains('dosa')) {
      fallbackCategoryDishes = const [
        FoodItem(
          id: 'cat_dish_south_1',
          name: 'Butter Masala Dosa',
          description: 'Crispy golden fermented crepe smeared with pure butter and spiced potato mash.',
          price: 139,
          imageUrl: 'assets/home_svg/cat_south_indian.jpg',
          category: 'South Indian',
          rating: 4.8,
          isVeg: true,
          nutrition: '360 kcal • 8g Protein • 54g Carbs',
          ingredients: ['Fermented Rice Batter', 'Spiced Potato Mash', 'Desi Butter', 'Curry Leaves'],
        ),
        FoodItem(
          id: 'cat_dish_south_2',
          name: 'Medu Vada Platter (3 Pcs)',
          description: 'Crispy golden lentil doughnuts served with piping hot dal sambar and coconut chutney.',
          price: 109,
          imageUrl: 'assets/home_svg/cat_south_indian.jpg',
          category: 'South Indian',
          rating: 4.7,
          isVeg: true,
          nutrition: '320 kcal • 12g Protein • 42g Carbs',
          ingredients: ['Black Gram Lentils', 'Black Pepper', 'Ginger', 'Coconut Oil'],
        ),
        FoodItem(
          id: 'cat_dish_south_3',
          name: 'Ghee Podi Thatte Idli',
          description: 'Soft steamed rice cakes tossed in fiery gun powder podi and hot ghee.',
          price: 119,
          imageUrl: 'assets/home_svg/cat_south_indian.jpg',
          category: 'South Indian',
          rating: 4.8,
          isVeg: true,
          nutrition: '290 kcal • 9g Protein • 48g Carbs',
          ingredients: ['Rice Flour', 'Urad Dal', 'Gunpowder Podi', 'Pure Cow Ghee'],
        ),
      ];
    } else {
      fallbackCategoryDishes = _canonicalSvgDishes();
    }

    final matched = allDishes.where((d) {
      if (_isVegOnly && !d.isVeg) return false;
      final dCat = d.category.toLowerCase();
      final dName = d.name.toLowerCase();
      return dCat.contains(cat) || dName.contains(cat);
    }).toList();

    final combined = [...matched];
    for (final fallback in fallbackCategoryDishes) {
      if (_isVegOnly && !fallback.isVeg) continue;
      if (!combined.any((d) => d.id == fallback.id || d.name == fallback.name)) {
        combined.add(fallback);
      }
    }

    return combined;
  }

  // ===========================================================================
  // 7. POPULAR RESTAURANTS SECTION
  // ===========================================================================
  Widget _buildPopularRestaurantsSection(HomeState state) {
    final allRestaurants = state.restaurants.isNotEmpty
        ? state.restaurants
        : RestaurantModel.defaultRestaurants();

    // Do NOT filter restaurants on category click (per requirement)
    final filtered = allRestaurants.where((r) {
      if (_isVegOnly && !r.isPureVeg) return false;
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Popular Restaurants',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1C1917),
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.menu),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),

          // Vertical List of Restaurant Cards matching SVG
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final restaurant = filtered[index];
              return _buildRestaurantCardItem(restaurant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCardItem(RestaurantModel restaurant) {
    // Generate distinct brand color badge for restaurant avatar
    Color brandColor = AppColors.primary;
    String brandInitial = restaurant.name.substring(0, 1).toUpperCase();
    if (restaurant.name.toLowerCase().contains('domino')) {
      brandColor = const Color(0xFF006491);
      brandInitial = 'D';
    } else if (restaurant.name.toLowerCase().contains('kfc')) {
      brandColor = const Color(0xFFE4002B);
      brandInitial = 'KFC';
    } else if (restaurant.name.toLowerCase().contains('biryani life')) {
      brandColor = const Color(0xFF1C1917);
      brandInitial = 'BL';
    } else if (restaurant.name.toLowerCase().contains('mcdonald')) {
      brandColor = const Color(0xFFDA291C);
      brandInitial = 'M';
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.menu, extra: restaurant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image with discount overlay & favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: restaurant.imageUrl.startsWith('http')
                        ? Image.network(
                            restaurant.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/home_svg/rest_mcdonalds.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            restaurant.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/biryani.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),

                // Dark Offer Pill Overlay on bottom left of image
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      restaurant.offerText,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // Favorite Heart Button on top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF44403C),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (Logo, Name, Rating, Cuisines, Time)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Brand Logo Square
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: brandColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          brandInitial,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: brandInitial.length > 1 ? 9.sp : 12.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Restaurant Name
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1C1917),
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Green Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${restaurant.rating}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF16A34A),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Cuisines Subtitle
                  Text(
                    restaurant.cuisine,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF78716C),
                      fontSize: 13.5.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Delivery Time & Ratings Count with Hygiene Verified Badge
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF78716C),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.deliveryTime,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF78716C),
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${restaurant.ratingCount})',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA8A29E),
                          fontSize: 12.sp,
                        ),
                      ),
                      const Spacer(),
                      // Hygiene Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF059669),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Hygiene Verified',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF047857),
                                fontSize: 11.sp,
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
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. TOP RATED DISHES SECTION
  // ===========================================================================
  Widget _buildTopRatedDishesSection(HomeState state) {
    // Get dishes from gourmet creations or canonical dishes matching the SVG
    final dishes = state.gourmetCreations.isNotEmpty
        ? state.gourmetCreations.map((g) => g.toFoodItem()).toList()
        : _canonicalSvgDishes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Top Rated Dishes',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1C1917),
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.menu),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.5.h),

        // Horizontal List of Dish Cards
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return _buildDishCardItem(dish, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDishCardItem(FoodItem dish, int index) {
    // Badges matching SVG: "Best Seller", "Popular", "Trending"
    String badgeText = 'Best Seller';
    Color badgeColor = const Color(0xFFDC2626);
    if (index % 3 == 1) {
      badgeText = 'Popular';
      badgeColor = const Color(0xFF16A34A);
    } else if (index % 3 == 2) {
      badgeText = 'Trending';
      badgeColor = const Color(0xFFEA580C);
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cartItem = cartState.items.cast<CartItem?>().firstWhere(
              (it) => it?.food.id == dish.id,
              orElse: () => null,
            );
        final qty = cartItem?.quantity ?? 0;

        return GestureDetector(
          onTap: () => context.push('/food-detail', extra: dish),
          child: Container(
            width: 165,
            margin: EdgeInsets.only(right: 3.5.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dish Image with Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: dish.imageUrl.startsWith('http')
                            ? Image.network(
                                dish.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  dish.fallbackImageAsset,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                dish.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  dish.fallbackImageAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    // Top Left Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    // Top Right Heart Icon
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                // Dish Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1C1917),
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${dish.rating}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1C1917),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(2K)',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA8A29E),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${dish.price.toInt()}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1C1917),
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          // Add button or Stepper
                          if (qty > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      context.read<CartCubit>().updateQuantity(dish, qty - 1);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      child: Icon(Icons.remove, size: 12, color: AppColors.primary),
                                    ),
                                  ),
                                  Text(
                                    '$qty',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      context.read<CartCubit>().addToCart(dish);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      child: Icon(Icons.add, size: 12, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                context.read<CartCubit>().addToCart(dish);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${dish.name} added to cart',
                                      style: GoogleFonts.inter(fontSize: 14.sp),
                                    ),
                                    backgroundColor: AppColors.primaryText,
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Canonical dishes directly matching Home Screen.svg
  List<FoodItem> _canonicalSvgDishes() {
    return const [
      FoodItem(
        id: 'svg_dish_1',
        name: 'Chicken Biryani',
        description: 'Fragrant basmati rice dum cooked with spiced tender chicken and saffron.',
        price: 249,
        imageUrl: 'assets/home_svg/dish_chicken_biryani.jpg',
        category: 'Biryani',
        rating: 4.5,
        isVeg: false,
        nutrition: '520 kcal • 32g Protein',
        ingredients: ['Basmati Rice', 'Chicken', 'Saffron', 'Whole Spices', 'Ghee'],
      ),
      FoodItem(
        id: 'svg_dish_2',
        name: 'Paneer Butter Masala',
        description: 'Rich and creamy cottage cheese cubes simmered in buttery tomato gravy.',
        price: 229,
        imageUrl: 'assets/home_svg/dish_paneer_masala.jpg',
        category: 'North Indian',
        rating: 4.4,
        isVeg: true,
        nutrition: '440 kcal • 18g Protein',
        ingredients: ['Paneer', 'Butter', 'Cashew Cream', 'Tomatoes', 'Kasuri Methi'],
      ),
      FoodItem(
        id: 'svg_dish_3',
        name: 'Margherita Pizza',
        description: 'Fresh basil, mozzarella cheese and rich pomodoro sauce on thin crust.',
        price: 199,
        imageUrl: 'assets/home_svg/dish_pizza.jpg',
        category: 'Pizza',
        rating: 4.3,
        isVeg: true,
        nutrition: '380 kcal • 14g Protein',
        ingredients: ['Wheat Flour Crust', 'Mozzarella', 'Basil', 'San Marzano Sauce'],
      ),
    ];
  }
}