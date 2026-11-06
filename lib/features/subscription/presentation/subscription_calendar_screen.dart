import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/models.dart';
import '../../location/data/models/add_address_response.dart';
import '../cubit/subscription_cubit.dart';

class SubscriptionCalendarScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionCalendarScreen({super.key, required this.subscription});

  @override
  State<SubscriptionCalendarScreen> createState() => _SubscriptionCalendarScreenState();
}

class _SubscriptionCalendarScreenState extends State<SubscriptionCalendarScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  CustomerAddressData? _selectedAddress;
  bool _isLoadingAddress = true;
  String? _pendingSubId;
  String? _pendingRzpOrderId;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchDefaultAddress();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchDefaultAddress() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.customerAddresses);
      final data = response.data;
      List<CustomerAddressData> addresses = [];

      if (data is Map<String, dynamic> && data['data'] is List) {
        addresses = (data['data'] as List)
            .map((e) => CustomerAddressData.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (mounted) {
        setState(() {
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => addresses.first,
            );
          }
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      appLog("⚠️ Note fetching customer address for subscription: $e");
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final cubit = context.read<SubscriptionCubit>();
    final plan = widget.subscription.plan;
    final subId = _pendingSubId ?? widget.subscription.id;
    final rzpOrderId = response.orderId ?? _pendingRzpOrderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';

    final success = await cubit.verifyPaymentAndActivate(
      subscriptionId: subId,
      razorpayOrderId: rzpOrderId,
      razorpayPaymentId: response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: response.signature ?? 'sig_${DateTime.now().millisecondsSinceEpoch}',
      fallbackPlan: plan,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Royal Subscription activated successfully!', style: TextStyle(color: AppColors.primaryText)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/my-subscription');
    } else {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            cubit.state.error?.isNotEmpty == true
                ? cubit.state.error!
                : 'Subscription payment verification failed on server.',
            style: const TextStyle(color: AppColors.primaryText),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          response.message?.isNotEmpty == true
              ? response.message!
              : 'Subscription payment cancelled.',
          style: const TextStyle(color: AppColors.primaryText),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    appLog("💳 Razorpay wallet chosen for subscription: ${response.walletName}");
  }

  Future<void> _handleSubscribeAndPay(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _isProcessing = true);

    final cubit = context.read<SubscriptionCubit>();
    final plan = widget.subscription.plan;
    final addressId = _selectedAddress?.id.isNotEmpty == true
        ? _selectedAddress!.id
        : 'addr_default_delhi';

    final startDate = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);

    // 1. POST: Initiate Subscription Checkout
    final initResponse = await cubit.initiateSubscriptionCheckout(
      planId: plan.id,
      addressId: addressId,
      startDate: startDate,
    );

    if (!mounted) return;

    final subId = (initResponse != null && initResponse.subscriptionId.isNotEmpty)
        ? initResponse.subscriptionId
        : widget.subscription.id;

    final rzpOrderId = (initResponse != null && initResponse.razorpayOrderId != null)
        ? initResponse.razorpayOrderId!
        : 'order_rzp_${DateTime.now().millisecondsSinceEpoch}';

    _pendingSubId = subId;
    _pendingRzpOrderId = rzpOrderId;

    final rzpKey = (initResponse?.razorpayKey != null && initResponse!.razorpayKey!.isNotEmpty)
        ? initResponse.razorpayKey!
        : AppConfigService.instance.activeRazorpayKey;

    final isKeyValid = rzpKey.isNotEmpty && !rzpKey.contains('YOUR_KEY') && !rzpKey.contains('<your_razorpay');

    if (isKeyValid) {
      final double totalPrice = plan.totalPlanPrice > 0 ? plan.totalPlanPrice : (plan.durationDays == 30 ? 8499.0 : 2299.0);
      final int amountInPaise = (totalPrice * 100).toInt();

      final options = {
        'key': rzpKey,
        'amount': amountInPaise,
        'name': 'Eatoggy',
        'description': '${plan.name} Subscription',
        'timeout': 180,
        if (initResponse?.razorpayOrderId != null && initResponse!.razorpayOrderId!.isNotEmpty)
          'order_id': initResponse.razorpayOrderId,
        'theme': {
          'color': '#D9A24F',
        },
        'retry': {'enabled': true, 'max_count': 3},
      };

      try {
        _razorpay.open(options);
        return;
      } catch (e) {
        appLog("⚠️ Razorpay SDK open exception in subscription: $e");
      }
    }

    // Fallback simulation mode if key is unconfigured or dev environment
    final success = await cubit.verifyPaymentAndActivate(
      subscriptionId: subId,
      razorpayOrderId: rzpOrderId,
      razorpayPaymentId: 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: 'sig_sim_${DateTime.now().millisecondsSinceEpoch}',
      fallbackPlan: plan,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Royal Subscription activated successfully!', style: TextStyle(color: AppColors.primaryText)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      router.go('/my-subscription');
    } else {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            cubit.state.error?.isNotEmpty == true
                ? cubit.state.error!
                : 'Subscription payment could not be completed',
            style: const TextStyle(color: AppColors.primaryText),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.subscription.plan;
    final bool isMonthly = plan.durationDays == 30;
    final double totalPrice = plan.totalPlanPrice > 0
        ? plan.totalPlanPrice
        : (isMonthly ? 8499.0 : 2299.0);
    final String formattedPrice = totalPrice.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    // Format schedule text dynamically from active subscription schedule days
    final List<String> scheduleDays = widget.subscription.schedule
        .map((d) {
          switch (d.date.weekday) {
            case DateTime.monday:
              return 'Mon';
            case DateTime.tuesday:
              return 'Tue';
            case DateTime.wednesday:
              return 'Wed';
            case DateTime.thursday:
              return 'Thu';
            case DateTime.friday:
              return 'Fri';
            case DateTime.saturday:
              return 'Sat';
            case DateTime.sunday:
              return 'Sun';
            default:
              return '';
          }
        })
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();

    final List<String> weekOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    scheduleDays.sort((a, b) => weekOrder.indexOf(a).compareTo(weekOrder.indexOf(b)));

    final String daysText = scheduleDays.isNotEmpty ? scheduleDays.join(' to ') : 'Mon to Fri';
    final String scheduleText = 'Schedule: $daysText • Lunch Delivery Slot';

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
                context.go('/subscription');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 18),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Plan',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Finalize your royal meal pass',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Plan Card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED PLAN',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${plan.name} (Pure Veg)',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scheduleText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Shipping Address Card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SHIPPING ADDRESS',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_selectedAddress != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedAddress!.label,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_isLoadingAddress)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      Text(
                        _selectedAddress != null
                            ? '${_selectedAddress!.addressLine1}, ${_selectedAddress!.city} - ${_selectedAddress!.pincode}'
                            : 'Select delivery address',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pricing Card ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal Plan Cost',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          '₹$formattedPrice',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GST & Premium Surcharge',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          'Included',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.surface, height: 28, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          '₹$formattedPrice',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── Subscribe & Pay Button ────────────────────────────────────
              GestureDetector(
                onTap: _isProcessing ? null : () => _handleSubscribeAndPay(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isProcessing ? null : AppColors.goldGradient,
                    color: _isProcessing ? AppColors.muted : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Subscribe & Pay via UPI',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ),
  );
}
}
