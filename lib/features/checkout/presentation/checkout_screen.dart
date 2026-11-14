import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../orders/presentation/cubit/order_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../data/models/checkout_summary_model.dart';
import '../../../widgets/custom_widgets.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cartState = context.read<CartCubit>().state;
        return CheckoutCubit()..loadCheckoutData(
          cartSubtotal: cartState.subtotal,
          discount: cartState.discountAmount,
        );
      },
      child: const _CheckoutScreenContent(),
    );
  }
}

class _CheckoutScreenContent extends StatefulWidget {
  const _CheckoutScreenContent();

  @override
  State<_CheckoutScreenContent> createState() => _CheckoutScreenContentState();
}

class _CheckoutScreenContentState extends State<_CheckoutScreenContent> {
  final List<Map<String, String>> _timeSlots = const [
    {'time': '12:30 - 1:15', 'label': 'Gourmet Lunch Slot'},
    {'time': '1:30 - 2:15', 'label': 'Gourmet Lunch Slot'},
    {'time': '7:30 - 8:15', 'label': 'Imperial Dinner Slot'},
  ];

  final List<Map<String, dynamic>> _paymentMethods = const [
    {
      'title': 'UPI',
      'subtitle': 'GPay, PhonePe, Paytm & more',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, Mastercard, RuPay',
      'icon': Icons.credit_card_outlined,
    },
    {
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when your royal feast arrives',
      'icon': Icons.money_outlined,
    },
  ];

  void _showAddressSelectionModal(BuildContext context, CheckoutState checkoutState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Delivery Address',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (checkoutState.addresses.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.location_off_outlined, color: AppColors.secondaryText, size: 40),
                          const SizedBox(height: 8),
                          Text('No saved addresses found', style: TextStyle(color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: checkoutState.addresses.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 16),
                      itemBuilder: (context, index) {
                        final address = checkoutState.addresses[index];
                        final isSelected = checkoutState.selectedAddress?.id == address.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : AppColors.surface,
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: isSelected ? Colors.black : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                address.label,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            [
                              address.addressLine1,
                              if (address.addressLine2.isNotEmpty && address.addressLine2 != address.addressLine1)
                                address.addressLine2,
                              address.city,
                              if (address.pincode.isNotEmpty) address.pincode,
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : const Icon(Icons.circle_outlined, color: AppColors.secondaryText),
                          onTap: () {
                            final cartState = context.read<CartCubit>().state;
                            context.read<CheckoutCubit>().selectAddress(
                              address,
                              fallbackSubtotal: cartState.subtotal,
                              discount: cartState.discountAmount,
                            );
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await context.push(AppRoutes.addAddress);
                    if (context.mounted) {
                      final cartState = context.read<CartCubit>().state;
                      context.read<CheckoutCubit>().loadCheckoutData(
                        cartSubtotal: cartState.subtotal,
                        discount: cartState.discountAmount,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '+ Add New Address',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
  }

  void _handlePlaceOrder(BuildContext context, CheckoutState checkoutState, CartState cartState) async {
    if (checkoutState.selectedAddress == null || checkoutState.selectedAddress!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedSlot = _timeSlots[checkoutState.selectedSlotIndex];
    final initiateResponse = await context.read<CheckoutCubit>().initiateCheckout(
      deliverySlot: {
        'slot': selectedSlot['label'],
        'time': selectedSlot['time'],
        'date': DateTime.now().toIso8601String().split('T').first,
      },
    );

    if (!mounted) return;

    final selectedMethod = _paymentMethods[checkoutState.selectedPaymentIndex]['title'] as String;

    if (initiateResponse != null || selectedMethod == 'Cash on Delivery') {
      final totalToPay = checkoutState.pricingSummary?.grandTotal ?? cartState.total;

      if (selectedMethod == 'Cash on Delivery') {
        // Direct order confirmation
        final orderItems = cartState.items
            .map((e) => OrderItem(food: e.food, quantity: e.quantity, price: e.food.price))
            .toList();

        final rawSessionId = initiateResponse?.checkoutSessionId ?? '';
        final orderId = (initiateResponse?.orderId != null && initiateResponse!.orderId!.isNotEmpty)
            ? initiateResponse.orderId!
            : (rawSessionId.isNotEmpty
                ? 'EAT-${rawSessionId.substring(0, rawSessionId.length > 8 ? 8 : rawSessionId.length)}'
                : 'EAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');

        final activeOrder = Order(
          id: orderId,
          items: orderItems,
          subtotal: checkoutState.pricingSummary?.subtotal ?? cartState.subtotal,
          discount: checkoutState.pricingSummary?.discount ?? cartState.discountAmount,
          deliveryFee: checkoutState.pricingSummary?.deliveryFee ?? 30.0,
          total: totalToPay,
          address: Address(
            id: checkoutState.selectedAddress!.id,
            name: checkoutState.selectedAddress!.name.isNotEmpty
                ? checkoutState.selectedAddress!.name
                : 'Primary',
            flatHouse: checkoutState.selectedAddress!.addressLine1.isNotEmpty
                ? checkoutState.selectedAddress!.addressLine1
                : 'Primary',
            street: checkoutState.selectedAddress!.addressLine2.isNotEmpty
                ? checkoutState.selectedAddress!.addressLine2
                : checkoutState.selectedAddress!.addressLine1,
            landmark: checkoutState.selectedAddress!.landmark ?? '',
            city: checkoutState.selectedAddress!.city,
            pincode: checkoutState.selectedAddress!.pincode,
            type: checkoutState.selectedAddress!.label,
          ),
          status: 'Active',
          orderTime: DateTime.now(),
          eta: '30-40 mins',
        );

        context.read<OrderCubit>().addOrder(activeOrder);
        context.read<CartCubit>().clearCart();
        context.go('/order-success', extra: activeOrder);
      } else if (initiateResponse != null) {
        // Navigate to payment processor with session data
        final selectedAddr = checkoutState.selectedAddress;
        final addressObj = selectedAddr != null
            ? Address(
                id: selectedAddr.id,
                name: selectedAddr.name.isNotEmpty ? selectedAddr.name : 'Primary',
                flatHouse: selectedAddr.addressLine1.isNotEmpty ? selectedAddr.addressLine1 : 'Primary',
                street: selectedAddr.addressLine2.isNotEmpty ? selectedAddr.addressLine2 : selectedAddr.addressLine1,
                landmark: selectedAddr.landmark ?? '',
                city: selectedAddr.city,
                pincode: selectedAddr.pincode,
                type: selectedAddr.label,
              )
            : null;

        context.push('/payment', extra: {
          'amount': totalToPay,
          'checkoutSessionId': initiateResponse.checkoutSessionId,
          'razorpayOrderId': initiateResponse.paymentGatewayOrderId,
          'razorpayKey': initiateResponse.razorpayKey,
          'address': addressObj,
        });
      }
    } else if (checkoutState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkoutState.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, checkoutState) {
        if (checkoutState.error != null && !checkoutState.isInitiatingOrder) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(checkoutState.error!), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, checkoutState) {
        final cartState = context.watch<CartCubit>().state;
        final pricing = checkoutState.pricingSummary ??
            CheckoutSummaryModel.fallback(cartState.subtotal, discount: cartState.discountAmount);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Checkout',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── 1. DELIVERING TO (Audited from GET /api/customers/addresses)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DELIVERING TO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            if (checkoutState.isLoadingAddresses)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      checkoutState.selectedAddress != null
                                          ? '${checkoutState.selectedAddress!.label} Delivery'
                                          : 'No Address Selected',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      checkoutState.selectedAddress != null
                                          ? [
                                              checkoutState.selectedAddress!.addressLine1,
                                              if (checkoutState.selectedAddress!.addressLine2.isNotEmpty &&
                                                  checkoutState.selectedAddress!.addressLine2 != checkoutState.selectedAddress!.addressLine1)
                                                checkoutState.selectedAddress!.addressLine2,
                                              '${checkoutState.selectedAddress!.city}${checkoutState.selectedAddress!.pincode.isNotEmpty ? ' - ${checkoutState.selectedAddress!.pincode}' : ''}',
                                            ].where((s) => s.isNotEmpty).join(', ')
                                          : 'Tap Change to select or add an address for delivery',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.secondaryText,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showAddressSelectionModal(context, checkoutState),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Change',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── 2. SELECT TIME SLOT ─────────────────────────────
                        Text(
                          'DELIVERY SLOT',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: List.generate(_timeSlots.length, (index) {
                            final isSelected = checkoutState.selectedSlotIndex == index;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => context.read<CheckoutCubit>().selectSlot(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    right: index < _timeSlots.length - 1 ? 8 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? AppColors.redGradient : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : AppColors.border,
                                      width: 1.2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _timeSlots[index]['time']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _timeSlots[index]['label']!.split(' ').first,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 28),

                        // ── 3. PREFERRED PAYMENT METHOD ──────────────────────
                        Text(
                          'PAYMENT METHOD',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...List.generate(_paymentMethods.length, (index) {
                          final method = _paymentMethods[index];
                          final isSelected = checkoutState.selectedPaymentIndex == index;

                          return GestureDetector(
                            onTap: () => context.read<CheckoutCubit>().selectPaymentMethod(index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    method['icon'] as IconData,
                                    color: isSelected ? AppColors.primary : AppColors.secondaryText,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method['title'] as String,
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          method['subtitle'] as String,
                                          style: GoogleFonts.inter(
                                            color: AppColors.secondaryText,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? AppColors.primary : AppColors.secondaryText,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 28),

                        // ── 4. AUDITED BILL DETAILS (GET /api/checkout/summary)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AUDITED BILL BREAKDOWN',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            if (checkoutState.isLoadingPricing)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Auditing...',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildBillRow('Item Subtotal', '₹${pricing.subtotal.toStringAsFixed(2)}'),
                              const SizedBox(height: 10),
                              _buildBillRow('GST & Restaurant Tax (5%)', '₹${pricing.gst.toStringAsFixed(2)}'),
                              const SizedBox(height: 10),
                              _buildBillRow('Eco Gourmet Packaging', '₹${pricing.packagingFee.toStringAsFixed(2)}'),
                              const SizedBox(height: 10),
                              _buildBillRow(
                                'Delivery Partner Fee',
                                pricing.deliveryFee == 0 ? 'FREE' : '₹${pricing.deliveryFee.toStringAsFixed(2)}',
                                isHighlight: pricing.deliveryFee == 0,
                              ),
                              const SizedBox(height: 10),
                              _buildBillRow('Platform Fee', '₹${pricing.platformFee.toStringAsFixed(2)}'),
                              if (pricing.discount > 0) ...[
                                const SizedBox(height: 10),
                                _buildBillRow(
                                  'Coupon Savings',
                                  '-₹${pricing.discount.toStringAsFixed(2)}',
                                  isHighlight: true,
                                ),
                              ],
                              const Divider(color: AppColors.border, height: 24, thickness: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'To Pay',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  Text(
                                    '₹${pricing.grandTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Confirm Order Button ─────────────────────────────
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpeedAnimatedButton(
                          text: 'Confirm Order • ₹${pricing.grandTotal.toStringAsFixed(2)}',
                          height: 56,
                          borderRadius: BorderRadius.circular(50),
                          isLoading: checkoutState.isInitiatingOrder,
                          textColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          onPressed: checkoutState.isInitiatingOrder
                              ? null
                              : () => _handlePlaceOrder(context, checkoutState, cartState),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isHighlight ? Colors.green : AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlight ? Colors.green : AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
