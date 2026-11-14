import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/profile_bloc.dart';
import '../data/models/get_profile_response.dart';
import '../data/repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _localAvatarPath;

  // Preset avatar choices for quick, reliable selection
  static const List<Map<String, String>> _presetAvatars = [
    {
      'name': 'Gourmet Chef',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Chef&backgroundColor=ffd5dc',
    },
    {
      'name': 'Food Connoisseur',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Gourmet&backgroundColor=ffdfba',
    },
    {
      'name': 'Royal Patron',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Royal&backgroundColor=bae1ff',
    },
    {
      'name': 'Healthy Gourmet',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Foodie&backgroundColor=baffc9',
    },
    {
      'name': 'Luxury Dining',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Luxury&backgroundColor=e8dff5',
    },
    {
      'name': 'Home Feast',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Feast&backgroundColor=ffffba',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalAvatar();
  }

  Future<void> _loadLocalAvatar() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final savedPath = prefs.getString('user_local_avatar_path');
      if (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync()) {
        if (mounted) {
          setState(() {
            _localAvatarPath = savedPath;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source, ProfileCustomer? customer) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _localAvatarPath = pickedFile.path;
      });

      // Save local path for instant persistence
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.setString('user_local_avatar_path', pickedFile.path);

      // Read image bytes and format as base64 data URI for server compatibility
      final bytes = await pickedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (mounted) {
        context.read<ProfileBloc>().add(
          UpdateCustomerProfileEvent(
            name: customer?.name,
            email: customer?.email,
            dietaryPreference: customer?.dietaryPreference,
            avatar: base64Image,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to select image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectPresetAvatar(String avatarUrl, ProfileCustomer? customer) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.remove('user_local_avatar_path');

      setState(() {
        _localAvatarPath = null;
      });

      if (mounted) {
        context.read<ProfileBloc>().add(
          UpdateCustomerProfileEvent(
            name: customer?.name,
            email: customer?.email,
            dietaryPreference: customer?.dietaryPreference,
            avatar: avatarUrl,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar selected successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _showImagePickerOptions(BuildContext context, ProfileCustomer? customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Photo',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Take a Photo
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Use camera to take a new picture',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.secondaryText),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.camera, customer);
                  },
                ),

                // 2. Choose from Gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Select an existing image from your device',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.secondaryText),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.gallery, customer);
                  },
                ),

                // 3. Choose from Curated Presets
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Choose Curated Avatar',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Pick from hand-crafted gourmet avatars',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.secondaryText),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showPresetAvatarsModal(context, customer);
                  },
                ),

                // 4. Remove Photo Option (if user has an avatar or local photo)
                if ((customer?.avatar != null && customer!.avatar!.isNotEmpty) ||
                    _localAvatarPath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Revert back to default initials avatar',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.secondaryText),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final prefs = await SharedPreferencesService.getInstance();
                      await prefs.remove('user_local_avatar_path');
                      setState(() {
                        _localAvatarPath = null;
                      });
                      if (context.mounted) {
                        context.read<ProfileBloc>().add(
                          UpdateCustomerProfileEvent(
                            name: customer?.name,
                            email: customer?.email,
                            dietaryPreference: customer?.dietaryPreference,
                            avatar: '',
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPresetAvatarsModal(BuildContext context, ProfileCustomer? customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (presetCtx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select an Avatar',
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(presetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _presetAvatars.length,
                itemBuilder: (context, index) {
                  final preset = _presetAvatars[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(presetCtx);
                      _selectPresetAvatar(preset['url']!, customer);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              preset['url']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(ProfileCustomer? customer) {
    final String? avatarUrl = customer?.avatar;
    final String displayName = (customer?.name != null && customer!.name!.isNotEmpty)
        ? customer.name!
        : (customer?.mobile != null && customer!.mobile.isNotEmpty ? customer.mobile : 'E');
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';

    Widget imageContent;

    if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty && File(_localAvatarPath!).existsSync()) {
      imageContent = Image.file(
        File(_localAvatarPath!),
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial),
      );
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final commaIdx = avatarUrl.indexOf(',');
          final b64 = commaIdx != -1 ? avatarUrl.substring(commaIdx + 1) : avatarUrl;
          final bytes = base64Decode(b64);
          imageContent = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 96,
            height: 96,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial),
          );
        } catch (_) {
          imageContent = _buildFallbackAvatar(initial);
        }
      } else {
        final fullUrl = avatarUrl.startsWith('http')
            ? avatarUrl
            : '${ApiConstants.serverUrl}/${avatarUrl.startsWith('/') ? avatarUrl.substring(1) : avatarUrl}';

        imageContent = Image.network(
          fullUrl,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFFFFE4E8),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
        );
      }
    } else {
      imageContent = _buildFallbackAvatar(initial);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _showImagePickerOptions(context, customer),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: imageContent),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: () => _showImagePickerOptions(context, customer),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(String initial) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE4E8),
            Color(0xFFFFD5DC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: 34.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(
        profileRepository: ProfileRepositoryImpl(),
      )..add(const FetchProfileEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Profile',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (state is ProfileFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 40.sp,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.error,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryText,
                          fontSize: 14.sp,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProfileBloc>().add(const FetchProfileEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final customer = (state is ProfileLoaded) ? state.customer : null;
            final mobile = customer?.mobile ?? '';
            final role = customer?.role ?? 'Customer';
            final isVerified = customer?.isMobileVerified ?? false;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                context.read<ProfileBloc>().add(const RefreshProfileEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ── Profile Header Section with Dynamic Interactive Avatar ──
                      _buildProfileAvatar(customer),
                      const SizedBox(height: 16),
                      Text(
                        (customer?.name != null && customer!.name!.isNotEmpty)
                            ? customer.name!
                            : (mobile.isNotEmpty ? '+91 $mobile' : 'Customer Profile'),
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      if (customer?.email != null && customer!.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          customer.email!,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isVerified ? Icons.verified : Icons.phone_android,
                            color: isVerified ? Colors.green : AppColors.secondaryText,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isVerified
                                ? (mobile.isNotEmpty ? '+91 $mobile • Verified' : 'Verified Customer')
                                : (mobile.isNotEmpty ? '+91 $mobile' : 'Registered Mobile'),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: isVerified ? Colors.green : AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary, width: 1.2),
                            ),
                            child: Text(
                              'VIP $role',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _showEditProfileModal(context, customer),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryText),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit Details',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Section 1: Orders & Subscriptions ─────────────────────────
                      _buildSectionHeader('ORDERS & MEALS'),
                      _buildCardGroup([
                        _buildMenuTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'My Orders',
                          subtitle: 'View active orders and past history',
                          onTap: () => context.push(AppRoutes.orders),
                        ),
                        _buildMenuTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'Tiffin Subscriptions',
                          subtitle: 'Manage recurring daily luxury meals',
                          onTap: () => context.push(AppRoutes.mySubscription),
                        ),
                        _buildMenuTile(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery Addresses',
                          subtitle: 'Saved home, office, and other locations',
                          onTap: () => context.push(AppRoutes.savedAddresses),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // ── Section 2: Perks & Feedback ───────────────────────────────
                      _buildSectionHeader('PERKS & EXPERIENCES'),
                      _buildCardGroup([
                        _buildMenuTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Offers & Coupons',
                          subtitle: 'Exclusive discounts and reward credits',
                          onTap: () => context.push(AppRoutes.offers),
                        ),
                        _buildMenuTile(
                          icon: Icons.rate_review_outlined,
                          title: 'My Reviews & Ratings',
                          subtitle: 'Past feedback on dishes and culinary chefs',
                          onTap: () => context.push(AppRoutes.myReviews),
                        ),
                        _buildMenuTile(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifications',
                          subtitle: 'Order updates and promotional alerts',
                          onTap: () => context.push(AppRoutes.notifications),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // ── Section 3: Support & Policies ────────────────────────────
                      _buildSectionHeader('PREFERENCES & LEGAL'),
                      _buildCardGroup([
                        _buildMenuTile(
                          icon: Icons.headset_mic_outlined,
                          title: 'Help & Support',
                          subtitle: 'Submit support tickets and reach concierge',
                          onTap: () => context.push(AppRoutes.support),
                        ),
                        _buildMenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Account Settings',
                          subtitle: 'Preferences and danger zone',
                          onTap: () => context.push(AppRoutes.settings),
                        ),
                        _buildMenuTile(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          subtitle: 'Eatoggy platform rules',
                          onTap: () => context.push(AppRoutes.terms),
                        ),
                        _buildMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we respect and secure your data',
                          onTap: () => context.push(AppRoutes.privacy),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Log Out Button ───────────────────────────────────────────
                      GestureDetector(
                        onTap: () => _confirmLogout(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // App Version
                      Text(
                        'Eatoggy User v1.0.0+1 • Luxury Dining Velocity',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your Eatoggy account?',
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgContext);
              final prefs = await SharedPreferencesService.getInstance();
              await prefs.clear();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: List.generate(children.length, (index) {
            final isLast = index == children.length - 1;
            return Column(
              children: [
                children[index],
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 52,
                    endIndent: 16,
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, ProfileCustomer? customer) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    String selectedDiet = (customer?.dietaryPreference != null && customer!.dietaryPreference!.isNotEmpty)
        ? customer.dietaryPreference!
        : 'VEG';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profile Details',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.secondaryText),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick photo change banner
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(modalCtx);
                        _showImagePickerOptions(context, customer);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Change Profile Photo',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField('Full Name', nameController, Icons.person_outline),
                    const SizedBox(height: 14),
                    _buildTextField('Email Address', emailController, Icons.email_outlined),
                    const SizedBox(height: 16),

                    Text(
                      'Dietary Preference',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['VEG', 'NON_VEG', 'JAIN'].map((diet) {
                        final isSelected = selectedDiet == diet;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedDiet = diet),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  diet.replaceAll('_', ' '),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.primaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        context.read<ProfileBloc>().add(
                          UpdateCustomerProfileEvent(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            dietaryPreference: selectedDiet,
                            avatar: customer?.avatar,
                          ),
                        );
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Updating profile...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: AppColors.primaryText, fontSize: 13.5.sp),
            decoration: InputDecoration(
              icon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
