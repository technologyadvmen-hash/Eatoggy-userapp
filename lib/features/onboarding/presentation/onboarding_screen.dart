import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entranceController;
  late final Animation<Offset> _bottomSheetSlide;
  late final Animation<double> _bottomSheetFade;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Authentic Home\nCooked Luxury',
      'description': 'Savor meticulously prepared traditional meals crafted by culinary experts, using heritage recipes and no preservatives.',
      'image': 'assets/o1.png',
    },
    {
      'title': 'Fresh Daily\nCooking',
      'image': 'assets/o2.png',
    },
    {
      'title': 'Seamless Doorstep\nDelivery',
      'description': 'Insulated hot-case delivery system ensures your meal arrives piping hot, exactly at your selected calendar slot.',
      'image': 'assets/o3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bottomSheetSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _bottomSheetFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();
  }

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentIndex) {
          _pageController.animateToPage(
            state.currentIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final currentIndex = state.currentIndex;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -250 && currentIndex < 2) {
                    // Swiped Left -> advance
                    context.read<OnboardingCubit>().nextPage();
                  } else if (details.primaryVelocity! > 250 && currentIndex > 0) {
                    // Swiped Right -> reverse
                    context.read<OnboardingCubit>().previousPage();
                  }
                }
              },
              child: Column(
                children: [
                  // Top Half: Animated Cross-Fade Image & Top Navigation Overlay
                  Stack(
                    children: [
                      SizedBox(
                        height: 48.h,
                        width: double.infinity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            _pages[currentIndex]['image']!,
                            key: ValueKey<String>(_pages[currentIndex]['image']!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 48.h,
                          ),
                        ),
                      ),
                      // Bottom gradient to blend image into background
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 10.h,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.6),
                                AppColors.background,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Top Buttons Overlay (Skip/Back)
                      if (currentIndex < 2)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 20,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back Button (Only visible on slide 2)
                              if (currentIndex == 1)
                                GestureDetector(
                                  onTap: () {
                                    context.read<OnboardingCubit>().previousPage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Back',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              
                              // Skip Button
                              GestureDetector(
                                onTap: _navigateToLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Skip',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // Bottom Half: Text Contents & Action Controls with Entrance Transition
                  Expanded(
                    child: FadeTransition(
                      opacity: _bottomSheetFade,
                      child: SlideTransition(
                        position: _bottomSheetSlide,
                        child: Container(
                          color: AppColors.background,
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 2.h),
                              // Page Title with AnimatedSwitcher
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _pages[currentIndex]['title']!,
                                  key: ValueKey<String>(_pages[currentIndex]['title']!),
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primary,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.5.h),
                              
                              // Description / Bullet list depending on the screen
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    context.read<OnboardingCubit>().setPage(index);
                                  },
                                  itemCount: _pages.length,
                                  itemBuilder: (context, index) {
                                    if (index == 1) {
                                      // Staggered Bullet Checklist for Slide 2
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildCheckItem(
                                            "Prepared fresh each morning",
                                            delayMs: 0,
                                            pageIndex: index,
                                          ),
                                          SizedBox(height: 2.h),
                                          _buildCheckItem(
                                            "Nutritionist-approved dynamic menus",
                                            delayMs: 100,
                                            pageIndex: index,
                                          ),
                                          SizedBox(height: 2.h),
                                          _buildCheckItem(
                                            "Premium farm-sourced organic ingredients",
                                            delayMs: 200,
                                            pageIndex: index,
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Standard Paragraph Description for Slides 1 and 3
                                      return Text(
                                        _pages[index]['description'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: AppColors.secondaryText,
                                          fontSize: 15.sp,
                                          height: 1.45,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              
                              // Bottom Buttons & Page Dots Indicators
                              if (currentIndex < 2)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildDotsIndicator(currentIndex),
                                      _buildNextButton(context),
                                    ],
                                  ),
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(child: _buildDotsIndicator(currentIndex)),
                                      SizedBox(height: 4.h),
                                      _buildGetStartedButton(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

  // Bullet point check mark widget with staggered entrance animation
  Widget _buildCheckItem(String text, {int delayMs = 0, required int pageIndex}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$text-$pageIndex'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1.0 - value) * 20, 0),
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dots indicator helper with active glowing shadow
  Widget _buildDotsIndicator(int currentIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? AppColors.primary : AppColors.muted,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // Next Button helper with Speed Cloche animation
  Widget _buildNextButton(BuildContext context) {
    return SpeedAnimatedButton(
      text: 'Next',
      width: 110,
      height: 48,
      borderRadius: BorderRadius.circular(16),
      onPressed: () {
        context.read<OnboardingCubit>().nextPage();
      },
    );
  }

  // Get Started Button helper with Speed Cloche animation
  Widget _buildGetStartedButton() {
    return PrimaryGoldButton(
      text: 'Get Started',
      onPressed: _navigateToLogin,
    );
  }
}
