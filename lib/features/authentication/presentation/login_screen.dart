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
import '../bloc/login_bloc.dart';
import '../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  late final AnimationController _entranceController;
  late final AnimationController _shakeController;
  late final AnimationController _btnPulseController;

  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _inputFade;
  late final Animation<Offset> _inputSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _shakeAnimation;
  late final Animation<double> _btnPulseAnimation;

  int _previousLength = 0;

  @override
  void initState() {
    super.initState();

    // 1. Entrance choreography controller (900ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeIn),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.06, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _inputFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
      ),
    );

    _inputSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.95, curve: Curves.easeIn),
      ),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
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
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _entranceController.dispose();
    _shakeController.dispose();
    _btnPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (context) => LoginBloc(authRepository: AuthRepositoryImpl()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is LoginOtpSentSuccess) {
                Helpers.showSuccessSnackbar('Success', state.message);
                context.go(AppRoutes.otp, extra: state.mobile);
              } else if (state is LoginFailure) {
                _shakeController.forward(from: 0.0);
                Helpers.showErrorSnackbar('Error', state.error);
              }
            },
            builder: (context, state) {
              final isLoading = state is LoginLoading;
              final isFocused = _phoneFocusNode.hasFocus;
              final hasContent = _phoneController.text.isNotEmpty;
              final isComplete = _phoneController.text.length == 10;

              return CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 3.h),

                          // 1. Top Centered Animated Eatoggy Logo
                          Center(
                            child: SlideTransition(
                              position: _logoSlide,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Image.asset(
                                  'assets/eatoggy_speed_logo.png',
                                  width: 52.w,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // 2. Animated Welcome Header
                          FadeTransition(
                            opacity: _headerFade,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Welcome to ',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primaryText,
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'EATOGGY',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primary,
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 1.5.h),
                                  Text(
                                    'Enter your mobile number to get fresh, hot\nmeals delivered straight to your door.',
                                    style: GoogleFonts.inter(
                                      color: AppColors.secondaryText,
                                      fontSize: 14.5.sp,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 3.5.h),

                          // 3. Input Label & Animated Phone Field
                          FadeTransition(
                            opacity: _inputFade,
                            child: SlideTransition(
                              position: _inputSlide,
                              child: AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_shakeAnimation.value, 0.0),
                                    child: child,
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'MOBILE NUMBER',
                                          style: GoogleFonts.outfit(
                                            color: isFocused ? AppColors.primary : AppColors.primaryText,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        if (hasContent)
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Text(
                                              '${_phoneController.text.length}/10',
                                              key: ValueKey(_phoneController.text.length),
                                              style: GoogleFonts.outfit(
                                                color: isComplete ? const Color(0xFF16A34A) : AppColors.secondaryText,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 1.5.h),

                                    // Phone Input Field Box with animated focus glow
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isComplete
                                              ? const Color(0xFF16A34A)
                                              : (isFocused || hasContent
                                                  ? AppColors.primary
                                                  : AppColors.border),
                                          width: isFocused || isComplete ? 1.8 : 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isComplete
                                                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                                : (isFocused
                                                    ? AppColors.primary.withValues(alpha: 0.14)
                                                    : Colors.black.withValues(alpha: 0.03)),
                                            blurRadius: isFocused || isComplete ? 12 : 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                                            decoration: BoxDecoration(
                                              color: isFocused
                                                  ? AppColors.primary.withValues(alpha: 0.08)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '🇮🇳 +91',
                                              style: GoogleFonts.outfit(
                                                color: AppColors.primaryText,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Container(
                                            width: 1.5,
                                            height: 24,
                                            color: isFocused ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                                          ),
                                          SizedBox(width: 3.w),
                                          Expanded(
                                            child: TextField(
                                              controller: _phoneController,
                                              focusNode: _phoneFocusNode,
                                              keyboardType: TextInputType.phone,
                                              onChanged: (val) {
                                                if (val.length == 10 && _previousLength != 10) {
                                                  HapticFeedback.lightImpact();
                                                  _btnPulseController.forward(from: 0.0);
                                                }
                                                _previousLength = val.length;
                                                setState(() {});
                                              },
                                              maxLength: 10,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                              style: GoogleFonts.outfit(
                                                color: AppColors.primaryText,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.8,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                counterText: "",
                                                hintText: 'Enter 10-digit number',
                                                hintStyle: GoogleFonts.inter(
                                                  color: AppColors.muted,
                                                  fontSize: 14.5.sp,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isComplete)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF16A34A),
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // 4. Continue Button with completion pulse & speed cloche
                          FadeTransition(
                            opacity: _buttonFade,
                            child: SlideTransition(
                              position: _buttonSlide,
                              child: ScaleTransition(
                                scale: _btnPulseAnimation,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 2.h),
                                  child: PrimaryGoldButton(
                                    text: 'Continue',
                                    isLoading: isLoading,
                                    onPressed: isComplete
                                        ? () {
                                            context.read<LoginBloc>().add(
                                                  LoginSendOtpEvent(
                                                    mobile: _phoneController.text,
                                                  ),
                                                );
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 5. Footer Disclaimer
                          FadeTransition(
                            opacity: _buttonFade,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 4.h),
                                child: Column(
                                  children: [
                                    Text(
                                      'By continuing, you agree to our',
                                      style: GoogleFonts.inter(
                                        color: AppColors.secondaryText,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        context.push(AppRoutes.terms);
                                      },
                                      child: Text(
                                        'Terms of Service & Privacy Policy',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.primary,
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
