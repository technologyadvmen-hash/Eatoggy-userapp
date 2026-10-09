import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

/// A premium, delightful button that triggers an animated Eatoggy speedy cloche
/// swooshing from left to right across the button on tap before executing [onPressed].
class SpeedAnimatedButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? logoAsset;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final Duration duration;
  final bool enableHaptics;

  const SpeedAnimatedButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height = 56,
    this.width,
    this.borderRadius,
    this.boxShadow,
    this.prefixIcon,
    this.suffixIcon,
    this.logoAsset,
    this.textStyle,
    this.padding,
    this.duration = const Duration(milliseconds: 400),
    this.enableHaptics = true,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  State<SpeedAnimatedButton> createState() => _SpeedAnimatedButtonState();
}

class _SpeedAnimatedButtonState extends State<SpeedAnimatedButton>
    with TickerProviderStateMixin {
  late final AnimationController _swooshController;
  late final AnimationController _pressController;
  late final AnimationController _loadingController;

  late final Animation<double> _slideAnimation;
  late final Animation<double> _scalePressAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _logoScaleAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // 1. Cloche Swoosh Controller
    _swooshController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Slide from left (-1.4) to right (+1.4)
    _slideAnimation = Tween<double>(begin: -1.4, end: 1.4).animate(
      CurvedAnimation(
        parent: _swooshController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Opacity: fade in quickly on entry, fade out smoothly on exit
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15.0,
      ),
    ]).animate(_swooshController);

    // Dynamic scale during the flight (slight swell at peak speed)
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.9).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0,
      ),
    ]).animate(_swooshController);

    // 2. Button Tactile Press Bounce
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scalePressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // 3. Continuous Loading Controller (Looping cloche glide)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpeedAnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _swooshController.dispose();
    _pressController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onPressed == null || widget.isLoading || _isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    // Trigger micro press down & release
    _pressController.forward().then((_) => _pressController.reverse());

    // Play swoosh animation
    try {
      await _swooshController.forward(from: 0.0);
    } catch (_) {
      // Ignored if cancelled
    }

    if (!mounted) return;

    setState(() {
      _isAnimating = false;
    });
    _swooshController.reset();

    // Fire the callback
    widget.onPressed?.call();
  }

  String _resolveLogoAsset(Color effectiveBg) {
    if (widget.logoAsset != null) return widget.logoAsset!;
    // If background is red/dark, use clean white contrast logo
    final isRedOrDark = effectiveBg == AppColors.primary ||
        effectiveBg == AppColors.primaryGold ||
        effectiveBg.computeLuminance() < 0.45;
    return isRedOrDark
        ? 'assets/eatoggy_speed_logo_white.png'
        : 'assets/eatoggy_speed_logo.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveBg = widget.backgroundColor ??
        (isEnabled ? AppColors.primary : AppColors.muted);
    final effectiveTextColor = widget.textColor ?? Colors.white;
    final effectiveBorderRadius = widget.borderRadius ??
        BorderRadius.circular(AppConstants.radiusButton);
    final logoAsset = _resolveLogoAsset(effectiveBg);

    return AnimatedBuilder(
      animation: _scalePressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scalePressAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: effectiveBorderRadius,
          boxShadow: isEnabled
              ? (widget.boxShadow ??
                  [
                    BoxShadow(
                      color: effectiveBg.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ])
              : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? _handleTap : null,
              borderRadius: effectiveBorderRadius,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Button Center Content
                  Padding(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: widget.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: effectiveTextColor,
                                  strokeWidth: 2.4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading...',
                                style: widget.textStyle ??
                                    theme.textTheme.bodyLarge?.copyWith(
                                      color: effectiveTextColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                              ),
                            ],
                          )
                        : (widget.child ??
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.prefixIcon != null) ...[
                                  widget.prefixIcon!,
                                  const SizedBox(width: 10),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.text ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: widget.textStyle ??
                                        theme.textTheme.bodyLarge?.copyWith(
                                          color: effectiveTextColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                  ),
                                ),
                                if (widget.suffixIcon != null) ...[
                                  const SizedBox(width: 10),
                                  widget.suffixIcon!,
                                ],
                              ],
                            )),
                  ),

                  // 2. Click Swoosh Animation (Single Trigger from Left to Right)
                  if (_isAnimating)
                    AnimatedBuilder(
                      animation: _swooshController,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: Align(
                            alignment: Alignment(_slideAnimation.value, 0.0),
                            child: Opacity(
                              opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Trailing light speed beam
                                    Container(
                                      width: 45,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Speedy Cloche Dish Tray Logo
                                    Image.asset(
                                      logoAsset,
                                      height: 36,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // 3. Continuous Looping Flight when Loading (Delivery in flight)
                  if (widget.isLoading)
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, _) {
                        final pos = -1.3 + (_loadingController.value * 2.6);
                        final alpha = (_loadingController.value < 0.2)
                            ? (_loadingController.value / 0.2)
                            : (_loadingController.value > 0.8)
                                ? (1.0 - _loadingController.value) / 0.2
                                : 1.0;
                        return Positioned.fill(
                          child: Align(
                            alignment: Alignment(pos, 0.0),
                            child: Opacity(
                              opacity: (alpha * 0.45).clamp(0.0, 1.0),
                              child: Image.asset(
                                logoAsset,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A versatile wrapper widget that enables the Eatoggy Speedy Cloche
/// left-to-right swoosh animation on ANY custom tapped card, button, or container.
class SpeedDeliveryWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final String? logoAsset;
  final Duration duration;
  final bool enableHaptics;

  const SpeedDeliveryWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.logoAsset,
    this.duration = const Duration(milliseconds: 380),
    this.enableHaptics = true,
  });

  @override
  State<SpeedDeliveryWrapper> createState() => _SpeedDeliveryWrapperState();
}

class _SpeedDeliveryWrapperState extends State<SpeedDeliveryWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slideAnimation = Tween<double>(begin: -1.3, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null || _isAnimating) return;
    setState(() => _isAnimating = true);

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    try {
      await _controller.forward(from: 0.0);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isAnimating = false);
    _controller.reset();

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onTap != null ? _handleTap : null,
            child: widget.child,
          ),
          if (_isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(_slideAnimation.value, 0.0),
                      child: Opacity(
                        opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                        child: Image.asset(
                          widget.logoAsset ?? 'assets/eatoggy_speed_logo_white.png',
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
