import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import 'cubit/order_cubit.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        final currentOrder = state.orders.firstWhere(
          (o) => o.id == order.id || o.id.contains(order.id) || order.id.contains(o.id),
          orElse: () => order,
        );

        // Determine status text and color
        final bool isPreparing = currentOrder.status == 'Active' &&
            DateTime.now().difference(currentOrder.orderTime).inMinutes < 10;
        
        final String statusText = currentOrder.status == 'Active'
            ? (isPreparing ? 'Preparing' : 'Out for Delivery')
            : currentOrder.status;

        final Color statusColor = statusText == 'Cancelled'
            ? AppColors.error
            : (statusText == 'Preparing' || statusText == 'Delivered')
                ? AppColors.success
                : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Order Details',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            backgroundColor: AppColors.background,
            iconTheme: const IconThemeData(color: AppColors.primaryText),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main Card (Order Info & Status) ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ORDER ID',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.secondaryText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${currentOrder.id}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(currentOrder.orderTime),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: statusColor, width: 1.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Items list in card
                        ...currentOrder.items.map((item) {
                          final isLast = currentOrder.items.indexOf(item) == currentOrder.items.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item.food.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.food.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _imgFallback(),
                                        )
                                      : _imgFallback(),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: item.food.isVeg ? Colors.green : Colors.red,
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: item.food.isVeg ? Colors.green : Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.food.name,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Qty: ${item.quantity} • Insulated Box Delivery',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Active order Countdown & Tracking
                        if (currentOrder.status == 'Active') ...[
                          const Divider(color: AppColors.border, height: 32, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ETA Countdown',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                currentOrder.eta.toLowerCase().contains('min') ? currentOrder.eta : '${currentOrder.eta} remaining',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 6,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => context.push('/tracking', extra: currentOrder),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Track Live Order',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showCancelOrderDialog(context, currentOrder),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.2),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel Order',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Delivery Address Card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${currentOrder.address.name} (${currentOrder.address.type})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          () {
                            final addr = currentOrder.address;
                            final parts = <String>[];
                            if (addr.flatHouse.isNotEmpty && addr.flatHouse != 'Delivery Address') {
                              parts.add(addr.flatHouse);
                            }
                            if (addr.street.isNotEmpty) {
                              parts.add(addr.street);
                            }
                            if (addr.city.isNotEmpty) {
                              if (addr.pincode.isNotEmpty) {
                                parts.add('${addr.city} - ${addr.pincode}');
                              } else {
                                parts.add(addr.city);
                              }
                            } else if (addr.pincode.isNotEmpty) {
                              parts.add(addr.pincode);
                            }
                            if (parts.isEmpty) {
                              return addr.flatHouse.isNotEmpty ? addr.flatHouse : 'Delivery Address';
                            }
                            return parts.join(', ');
                          }(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Bill Details Card ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Receipt Breakdown',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBreakdownRow('Order Placed', _formatDate(currentOrder.orderTime)),
                        _buildBreakdownRow('Subtotal', '₹${currentOrder.subtotal.toStringAsFixed(0)}'),
                        _buildBreakdownRow('Discount', '-₹${currentOrder.discount.toStringAsFixed(0)}', isDiscount: true),
                        _buildBreakdownRow('Delivery Fee', '₹${currentOrder.deliveryFee.toStringAsFixed(0)}'),
                        const Divider(color: AppColors.border, height: 24, thickness: 1),
                        _buildBreakdownRow('Total Amount', '₹${currentOrder.total.toStringAsFixed(0)}', isTotal: true),
                      ],
                    ),
                  ),
                  if (currentOrder.status.toLowerCase() == 'delivered') ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        context.push('/write-review', extra: currentOrder);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.primaryText, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Write a Review',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} • $hour:$min $ampm';
  }

  Widget _imgFallback() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restaurant, color: AppColors.muted, size: 24),
      );

  Widget _buildBreakdownRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15.sp : 14.sp,
              color: isTotal ? AppColors.primaryText : AppColors.secondaryText,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              color: isDiscount
                  ? AppColors.success
                  : (isTotal ? AppColors.primary : AppColors.primaryText),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context, Order order) {
    String selectedReason = "Changed my mind";
    final List<String> reasons = [
      "Changed my mind",
      "Placed by mistake",
      "Order taking longer than expected",
      "Delivery address was incorrect",
      "Other",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cancel Order #${order.id}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.secondaryText),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to cancel this order? Any payments made will be refunded to the original payment source.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please select a reason',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return InkWell(
                      onTap: () => setSheetState(() => selectedReason = r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSel ? AppColors.primary : AppColors.secondaryText,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              r,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isSel ? AppColors.primaryText : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                'Keep Order',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.of(sheetCtx).pop();
                            final orderCubit = context.read<OrderCubit>();
                            await orderCubit.cancelOrder(
                              order.id,
                              reason: selectedReason,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order cancelled successfully.'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              if (context.canPop()) {
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (context.mounted && context.canPop()) {
                                    context.pop();
                                  }
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Confirm Cancel',
                                style: TextStyle(
                                  fontSize: 13.sp,
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
      },
    );
  }
}
