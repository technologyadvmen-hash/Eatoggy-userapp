import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../core/utils/app_lifecycle_helper.dart';
import '../../core/theme/app_colors.dart';

class NavigationShell extends StatefulWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  DateTime? _lastBackPressTime;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/subscription')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/orders'); break;
      case 2: context.go('/subscription'); break;
      case 3: context.go('/profile'); break;
    }
  }

  void _handleBackPress(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    // 1. If on any tab other than Home, navigate back to Home first
    if (currentIndex != 0) {
      context.go('/home');
      return;
    }

    // 2. If on Home, require double-tap back within 2 seconds to exit/minimize
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Press back again to exit',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryText,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: 9.h,
            left: 6.w,
            right: 6.w,
          ),
        ),
      );
      return;
    }

    // Double-press confirmed: smoothly move to background without destroying the activity
    AppLifecycleHelper.moveToBackground();
  }

  @override
  Widget build(BuildContext context) {
    const Color activeRed = AppColors.primary;
    const Color inactiveGrey = AppColors.secondaryText;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress(context);
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          padding: EdgeInsets.symmetric(vertical: 0.5.h),
          child: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            backgroundColor: AppColors.surface,
            selectedItemColor: activeRed,
            unselectedItemColor: inactiveGrey,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            selectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14.5.sp,
              color: activeRed,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13.5.sp,
              color: const Color(0xFF57534E),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home_rounded, size: 23, color: activeRed),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_rounded, size: 22),
                activeIcon: Icon(Icons.access_time_filled_rounded, size: 23, color: activeRed),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined, size: 22),
                activeIcon: Icon(Icons.calendar_month_rounded, size: 23, color: activeRed),
                label: 'Subscription',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 23, color: activeRed),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
