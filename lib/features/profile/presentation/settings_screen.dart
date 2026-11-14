import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/session_manager.dart';
import '../data/models/delete_account_request.dart';
import '../data/repositories/profile_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsWhatsAppAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferencesService.getInstance();
    if (mounted) {
      setState(() {
        _pushNotifications = prefs.getBool(AppKeys.prefPushNotifications) ?? true;
        _emailNotifications = prefs.getBool(AppKeys.prefEmailNotifications) ?? false;
        _smsWhatsAppAlerts = prefs.getBool(AppKeys.prefSmsWhatsAppAlerts) ?? true;
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notification preference updated',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryText,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                context.go('/profile');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 18),
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Notifications Preferences ──────────────────────────────────
              Text(
                'Notifications Preferences',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              _buildToggleCard(
                title: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (val) {
                  setState(() => _pushNotifications = val);
                  _savePreference(AppKeys.prefPushNotifications, val);
                },
              ),
              _buildToggleCard(
                title: 'Email Notifications',
                value: _emailNotifications,
                onChanged: (val) {
                  setState(() => _emailNotifications = val);
                  _savePreference(AppKeys.prefEmailNotifications, val);
                },
              ),
              _buildToggleCard(
                title: 'SMS & WhatsApp Alerts',
                value: _smsWhatsAppAlerts,
                onChanged: (val) {
                  setState(() => _smsWhatsAppAlerts = val);
                  _savePreference(AppKeys.prefSmsWhatsAppAlerts, val);
                },
              ),
              const SizedBox(height: 24),

              // ── App Settings ──────────────────────────────────────────────
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              _buildLanguageCard(),
              _buildLinkCard(
                title: 'Terms of Service',
                onTap: () => context.push(AppRoutes.terms),
              ),
              _buildLinkCard(
                title: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.privacy),
              ),
              _buildLinkCard(
                title: 'Refunds & Cancellations',
                onTap: () => context.push(AppRoutes.refund),
              ),
              _buildLinkCard(
                title: 'About EATOGGY',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eatoggy v4.12.0 Express Delivery')),
                  );
                },
              ),
              const SizedBox(height: 36),

              // ── App Info Footer with New Speed Logo ───────────────────────
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/eatoggy_speed_logo.png',
                      width: 32.w,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EATOGGY Express Delivery Client',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v4.12.0',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Logout Button ──────────────────────────────────────────────
              GestureDetector(
                onTap: () => _showLogoutConfirmation(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Delete Account Button (Mandatory for App Stores) ───────────
              GestureDetector(
                onTap: () => _showDeleteAccountConfirmation(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Delete Account & Data',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: AppColors.background,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.muted,
              inactiveTrackColor: AppColors.surface,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'App Language',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          Row(
            children: [
              Text(
                'English (US)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: AppColors.secondaryText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out of EATOGGY?',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(sheetCtx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        try {
                          await ApiService.dio.post(ApiConstants.logout);
                          appLog("✅ Logged out from backend session");
                        } catch (e) {
                          appLog("⚠️ Backend logout warning: $e");
                        }
                        await SessionManager.forceLogout();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final reasonController = TextEditingController(text: "Not using the app anymore");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete your Eatoggy account? All saved addresses, order history, active subscriptions, and personal data will be scheduled for permanent deletion.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for leaving',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: reasonController,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter reason (optional)',
                    hintStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(sheetCtx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        try {
                          final repo = ProfileRepositoryImpl();
                          await repo.deleteAccount(
                            DeleteAccountRequest(reason: reasonController.text.trim()),
                          );
                          appLog("✅ Account deletion requested successfully");
                        } catch (e) {
                          appLog("⚠️ Account deletion error: $e");
                        }
                        await SessionManager.forceLogout();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
