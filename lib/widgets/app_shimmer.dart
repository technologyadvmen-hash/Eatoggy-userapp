import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  /// Factory constructor for a rounded rectangle skeleton (e.g. food cards)
  factory AppShimmer.card({
    required double width,
    required double height,
    double borderRadius = 12.0,
  }) {
    return AppShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Factory constructor for a circular skeleton (e.g. profile pictures)
  factory AppShimmer.circle({
    required double size,
  }) {
    return AppShimmer(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }

  /// Factory constructor for a line of text
  factory AppShimmer.text({
    required double width,
    double height = 14.0,
  }) {
    return AppShimmer(
      width: width,
      height: height,
      borderRadius: 4.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
