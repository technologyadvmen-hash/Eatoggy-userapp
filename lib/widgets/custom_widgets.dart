import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import 'speed_animated_button.dart';

export 'speed_animated_button.dart';

class PrimaryGoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryGoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedAnimatedButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            side: const BorderSide(color: AppColors.muted, width: 1.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class OutlineButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const OutlineButtonWidget({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? errorText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.errorText,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          buildCounter: maxLength != null
              ? (context, {required currentLength, required isFocused, maxLength}) =>
                  null
              : null,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            counterText: "",
            hintText: hintText,
            hintStyle:
                theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surface,
            errorText: errorText,
            errorStyle:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
