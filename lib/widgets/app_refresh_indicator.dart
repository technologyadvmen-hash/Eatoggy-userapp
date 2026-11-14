import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      displacement: 40.0,
      strokeWidth: 3.0,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
