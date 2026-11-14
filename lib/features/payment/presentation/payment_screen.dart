import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/dummy_data.dart';
import '../../../shared/models/models.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../checkout/data/models/verify_payment_request.dart';
import '../../checkout/data/repositories/checkout_repository.dart';
import '../../orders/presentation/cubit/order_cubit.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String? checkoutSessionId;
  final String? razorpayOrderId;
  final String? razorpayKey;
  final Address? address;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.checkoutSessionId,
    this.razorpayOrderId,
    this.razorpayKey,
    this.address,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = true;
  String? _statusMessage = 'Initializing Secure Razorpay Gateway...';
  String? _errorMessage;
  bool _isKeyPending = false;
  String _userMobile = '9876543210';
  String _userEmail = 'customer@eatoggy.in';

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadUserDetailsAndLaunch();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadUserDetailsAndLaunch() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final userJson = prefs.getString(AppKeys.user);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        if (userMap['mobile'] != null) _userMobile = userMap['mobile'].toString();
        if (userMap['email'] != null) _userEmail = userMap['email'].toString();
      }
    } catch (_) {}

    _launchRazorpayCheckout();
  }

  void _launchRazorpayCheckout() {
    final key = (widget.razorpayKey != null && widget.razorpayKey!.isNotEmpty)
        ? widget.razorpayKey!
        : AppConfigService.instance.activeRazorpayKey;

    if (key.isEmpty || key.contains('YOUR_KEY') || key.contains('<your_razorpay')) {
      setState(() {
        _isProcessing = false;
        _isKeyPending = true;
        _errorMessage =
            'Razorpay Key ID is not configured yet. Provide your active Razorpay Key in app_keys.dart or configure it on your backend.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _isKeyPending = false;
      _statusMessage = 'Opening Razorpay Payment Sheet...';
    });

    final int amountInPaise = (widget.amount > 0 ? widget.amount * 100 : 100).toInt();

    final options = {
      'key': key,
      'amount': amountInPaise,
      'name': 'Eatoggy',
      'description': 'Royal Feast Order Payment',
      'timeout': 180,
      if (widget.razorpayOrderId != null && widget.razorpayOrderId!.isNotEmpty)
        'order_id': widget.razorpayOrderId,
      'prefill': {
        'contact': _userMobile,
        'email': _userEmail,
      },
      'theme': {
        'color': '#D9A24F',
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      appLog("⚠️ Razorpay SDK open exception: $e");
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Could not open Razorpay checkout: $e';
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment on Eatoggy servers...';
      _errorMessage = null;
    });

    final checkoutRepo = CheckoutRepositoryImpl();
    final cartCubit = context.read<CartCubit>();
    String? verifiedOrderId;

    try {
      final sessionId = widget.checkoutSessionId ??
          'chk_session_${DateTime.now().millisecondsSinceEpoch}';

      final verifyRequest = VerifyPaymentRequest(
        checkoutSessionId: sessionId,
        razorpayOrderId: response.orderId ??
            widget.razorpayOrderId ??
            'order_${DateTime.now().millisecondsSinceEpoch}',
        razorpayPaymentId: response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        razorpaySignature: response.signature ?? 'sig_${DateTime.now().millisecondsSinceEpoch}',
      );

      final verifyResponse = await checkoutRepo.verifyPayment(verifyRequest);
      if (verifyResponse.orderId != null && verifyResponse.orderId!.isNotEmpty) {
        verifiedOrderId = verifyResponse.orderId;
        appLog("✅ Order verified on backend: $verifiedOrderId");
      }
    } catch (e) {
      appLog("⚠️ Payment verification backend note: $e");
    }

    if (!mounted) return;

    final orderId = verifiedOrderId ?? 'EAT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final orderItems = cartCubit.state.items
        .map((e) => OrderItem(food: e.food, quantity: e.quantity, price: e.food.price))
        .toList();

    Address deliveryAddress = widget.address ?? DummyData.sampleAddress;
    if (widget.address == null ||
        widget.address!.city.toLowerCase() == 'gurugram' ||
        widget.address!.city.isEmpty) {
      try {
        final prefs = await SharedPreferencesService.getInstance();
        final currentAddr = prefs.getString(AppKeys.currentAddress);
        if (currentAddr != null && currentAddr.trim().isNotEmpty) {
          final parts = currentAddr.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
          final savedCity = prefs.getString('current_city');
          final savedPin = prefs.getString('current_pincode');
          deliveryAddress = Address(
            id: widget.address?.id ?? 'addr_current',
            name: (widget.address != null && widget.address!.name.isNotEmpty)
                ? widget.address!.name
                : (prefs.getString(AppKeys.userName) ?? 'Delivery Address'),
            flatHouse: parts.isNotEmpty ? parts.first : 'Delivery Address',
            street: currentAddr.trim(),
            landmark: widget.address?.landmark ?? '',
            city: (savedCity != null && savedCity.isNotEmpty && savedCity.toLowerCase() != 'gurugram')
                ? savedCity
                : (parts.length > 2
                    ? parts[parts.length - 2].replaceAll(RegExp(r'\b\d{6}\b'), '').trim()
                    : (parts.length > 1 ? parts[1].replaceAll(RegExp(r'\b\d{6}\b'), '').trim() : 'Local')),
            pincode: (savedPin != null && savedPin.isNotEmpty && savedPin != '122002')
                ? savedPin
                : (RegExp(r'\b\d{6}\b').firstMatch(currentAddr)?.group(0) ?? ''),
            type: widget.address?.type ?? 'Home',
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final order = Order(
      id: orderId,
      items: orderItems,
      subtotal: cartCubit.state.subtotal,
      discount: cartCubit.state.discountAmount,
      deliveryFee: 30.0,
      total: widget.amount > 0 ? widget.amount : cartCubit.state.total,
      address: deliveryAddress,
      status: 'Active',
      orderTime: DateTime.now(),
      eta: '30-35 mins',
    );

    context.read<OrderCubit>().addOrder(order);
    cartCubit.clearCart();

    context.go('/order-success', extra: order);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    appLog("❌ Razorpay payment error: [${response.code}] ${response.message}");
    setState(() {
      _isProcessing = false;
      _errorMessage = response.message?.isNotEmpty == true
          ? response.message
          : 'Payment was cancelled or could not be completed.';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    appLog("💳 Razorpay external wallet chosen: ${response.walletName}");
  }

  void _simulateTestSuccess() {
    _handlePaymentSuccess(
      PaymentSuccessResponse(
        'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
        widget.razorpayOrderId ?? 'order_sim_${DateTime.now().millisecondsSinceEpoch}',
        'sig_sim_${DateTime.now().millisecondsSinceEpoch}',
        null,
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Secure Payment',
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go('/cart');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing) ...[
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _statusMessage ?? 'Connecting to Razorpay...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please do not press back or close the app.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isKeyPending
                          ? const Color(0xFFFEF3C7)
                          : AppColors.accentLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isKeyPending ? AppColors.primary : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _isKeyPending ? Icons.vpn_key_outlined : Icons.error_outline,
                      size: 32,
                      color: _isKeyPending ? AppColors.primary : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isKeyPending ? 'Razorpay Key Configuration' : 'Payment Failed',
                    style: GoogleFonts.outfit(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!_isKeyPending)
                    GestureDetector(
                      onTap: _launchRazorpayCheckout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Retry Razorpay Payment',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isKeyPending)
                    GestureDetector(
                      onTap: _simulateTestSuccess,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Simulate Test Payment (Dev Mode)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        GoRouter.of(context).pop();
                      } else {
                        context.go('/checkout');
                      }
                    },
                    child: Text(
                      'Return to Checkout',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
