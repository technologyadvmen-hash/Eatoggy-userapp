import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../widgets/custom_widgets.dart';
import '../bloc/otp_bloc.dart';
import '../data/repositories/auth_repository.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 45;
  int _prevLength = 0;

  late final AnimationController _entranceController;
  late final AnimationController _shakeController;
  late final AnimationController _btnPulseController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _otpFade;
  late final Animation<Offset> _otpSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _shakeAnimation;
  late final Animation<double> _btnPulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // 1. Entrance Choreography Controller (800ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _otpFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeIn),
      ),
    );

    _otpSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeIn),
      ),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Shake error controller (400ms)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    // 3. Button Pulse on completion (350ms)
    _btnPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _btnPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_btnPulseController);

    _entranceController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _entranceController.dispose();
    _shakeController.dispose();
    _btnPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtpBloc>(
      create: (context) => OtpBloc(authRepository: AuthRepositoryImpl()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<OtpBloc, OtpState>(
            listener: (context, state) {
              if (state is OtpVerificationSuccess) {
                Helpers.showSuccessSnackbar('Success', state.message);
                context.go(AppRoutes.locationPermission);
              } else if (state is OtpFailure) {
                _shakeController.forward(from: 0.0);
                Helpers.showErrorSnackbar('Error', state.error);
              } else if (state is OtpResentSuccess) {
                Helpers.showSuccessSnackbar('Success', state.message);
                setState(() {
                  _secondsRemaining = 45;
                });
                _startTimer();
              }
            },
            builder: (context, state) {
              final isLoading = state is OtpLoading;
              final minutes = (_secondsRemaining ~/ 60).toString();
              final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
              final timeText = "$minutes:$seconds";
              final isComplete = _otpController.text.length == 6;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Back button
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primary,
                          size: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // 1. Header & Subtitle with slide-down
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Code',
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryText,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 1.5.h),
                            RichText(
                              text: TextSpan(
                                text: 'We have sent a 6-digit verification code to ',
                                style: GoogleFonts.inter(
                                  color: AppColors.secondaryText,
                                  fontSize: 14.5.sp,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(
                                    text: '+91 ${widget.phoneNumber}',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // 2. Styled 6-digit OTP Inputs with Shake & Glow
                    FadeTransition(
                      opacity: _otpFade,
                      child: SlideTransition(
                        position: _otpSlide,
                        child: AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0.0),
                              child: child,
                            );
                          },
                          child: OtpInputWidget(
                            controller: _otpController,
                            length: 6,
                            onChanged: (val) {
                              if (val.length == 6 && _prevLength != 6) {
                                HapticFeedback.lightImpact();
                                _btnPulseController.forward(from: 0.0);
                              }
                              _prevLength = val.length;
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // 3. Timer / Resend Indicator
                    FadeTransition(
                      opacity: _otpFade,
                      child: Center(
                        child: _secondsRemaining > 0
                            ? RichText(
                                text: TextSpan(
                                  text: 'Resend code in ',
                                  style: GoogleFonts.inter(
                                    color: AppColors.secondaryText,
                                    fontSize: 12.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: timeText,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        context.read<OtpBloc>().add(
                                          ResendOtpEvent(
                                            mobile: widget.phoneNumber,
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Resend Code',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5.sp,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Change mobile link
                    FadeTransition(
                      opacity: _otpFade,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: Text(
                            'Change Mobile Number',
                            style: GoogleFonts.inter(
                              color: AppColors.secondaryText,
                              fontSize: 12.sp,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 4. Verify & Proceed Action Button with pulse
                    FadeTransition(
                      opacity: _buttonFade,
                      child: SlideTransition(
                        position: _buttonSlide,
                        child: ScaleTransition(
                          scale: _btnPulseAnimation,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: PrimaryGoldButton(
                              text: 'Verify & Proceed',
                              isLoading: isLoading,
                              onPressed: isComplete
                                  ? () {
                                      context.read<OtpBloc>().add(
                                        VerifyOtpSubmitEvent(
                                          mobile: widget.phoneNumber,
                                          otp: _otpController.text,
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Custom OTP Input Layout with Blinking Caret Support
class OtpInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onChanged;

  const OtpInputWidget({
    super.key,
    required this.controller,
    this.length = 6,
    required this.onChanged,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        children: [
          // Hidden input field for native processing
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              height: 1,
              width: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                onChanged: widget.onChanged,
                showCursor: false,
                decoration: const InputDecoration(
                  counterText: "",
                ),
              ),
            ),
          ),

          // Row of styled verification code boxes matching SVG layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final text = widget.controller.text;
              final hasChar = index < text.length;
              final char = hasChar ? text[index] : "";
              final isFocused = _focusNode.hasFocus && text.length == index;

              final boxWidth = widget.length == 6 ? 12.8.w : 18.w;
              final boxHeight = widget.length == 6 ? 14.w : 18.w;
              final fontSize = widget.length == 6 ? 18.sp : 22.sp;

              return AnimatedScale(
                scale: hasChar ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? AppColors.primary
                          : (hasChar ? AppColors.primaryText : AppColors.border),
                      width: isFocused ? 2.0 : (hasChar ? 1.5 : 1.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFocused
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : (hasChar
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.02)),
                        blurRadius: isFocused ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isFocused
                        ? const BlinkingCursor()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            transitionBuilder: (child, anim) {
                              return ScaleTransition(
                                scale: anim,
                                child: child,
                              );
                            },
                            child: Text(
                              char,
                              key: ValueKey(char),
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryText,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Dynamic Blinking Line Caret Indicator
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.0,
        height: 24.0,
        color: AppColors.primary,
      ),
    );
  }
}
