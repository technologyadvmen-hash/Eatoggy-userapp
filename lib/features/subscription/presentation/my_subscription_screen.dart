import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_widgets.dart';
import '../cubit/subscription_cubit.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Load customer subscriptions on entrance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionCubit>().loadMySubscriptions();
    });
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => context.read<SubscriptionCubit>().loadMySubscriptions(),
          ),
        ],
      ),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state.actionMessage != null && state.actionMessage!.trim().isNotEmpty) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  state.actionMessage!,
                  style: const TextStyle(color: AppColors.primaryText),
                ),
                backgroundColor: AppColors.surface,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          final sub = state.activeSubscription;

          if (state.isLoading && sub == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (sub == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 80, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Subscription',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get daily fresh food packages delivered directly.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 220,
                      child: PrimaryGoldButton(
                        text: 'Explore Plans',
                        onPressed: () => context.go('/subscription'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final String planName = sub.plan.name.isNotEmpty ? sub.plan.name : 'Maharaja Royal Veg Pass';
          final bool isActive = sub.status.toUpperCase() == 'ACTIVE';

          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await context.read<SubscriptionCubit>().loadMySubscriptions();
              },
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Subscription',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your bespoke daily diet & delivery schedule',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (state.mySubscriptions.length > 1) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: state.mySubscriptions.map((item) {
                            final isSelected = item.id == sub.id;
                            return GestureDetector(
                              onTap: () {
                                context.read<SubscriptionCubit>().activateSubscription(item);
                                context.read<SubscriptionCubit>().fetchSubscriptionTimeline(item.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.surface,
                                  ),
                                ),
                                child: Text(
                                  '${item.plan.name.split(" ").first} (${item.status})',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  const SizedBox(height: 24),

                  // ── Active Plan Card ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan Name & Active Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                planName,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.greenLight : AppColors.accentLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                sub.status,
                                style: TextStyle(
                                  color: isActive ? AppColors.greenText : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats (Remaining meals & Next Delivery)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REMAINING MEALS',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${sub.remainingMeals} / ${sub.plan.totalMeals}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEXT DELIVERY',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isActive ? 'Tomorrow, 12:30 PM' : 'Paused',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppColors.primary : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Actions (Pause/Resume & Details)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: state.isMutating
                                    ? null
                                    : () {
                                        if (isActive) {
                                          context.read<SubscriptionCubit>().pauseSubscription();
                                        } else {
                                          context.read<SubscriptionCubit>().resumeSubscription();
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.surface, width: 1.5),
                                    color: AppColors.background,
                                  ),
                                  child: Center(
                                    child: state.isMutating
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                          )
                                        : Text(
                                            isActive ? 'Pause Plan' : 'Resume Plan',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showPlanDetailsModal(context, sub),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.surface, width: 1.5),
                                    color: AppColors.background,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Plan Details',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
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
                  ),
                  const SizedBox(height: 24),

                  // ── Upcoming Deliveries / Calendar Schedule Section ────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Deliveries',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${sub.schedule.length} Days',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (sub.schedule.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No upcoming delivery occurrences scheduled.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sub.schedule.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final day = sub.schedule[index];
                        final isSkipped = day.status.toUpperCase() == 'SKIPPED';
                        final isDelivered = day.status.toUpperCase() == 'DELIVERED';
                        final isUpcoming = !isSkipped && !isDelivered;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSkipped
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : AppColors.surface,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSkipped
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : (isDelivered
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSkipped
                                      ? Icons.close
                                      : (isDelivered ? Icons.check : Icons.lunch_dining),
                                  color: isSkipped
                                      ? Colors.red
                                      : (isDelivered ? Colors.green : AppColors.primary),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(day.date),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSkipped
                                            ? AppColors.muted
                                            : AppColors.primaryText,
                                        decoration: isSkipped ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isSkipped
                                          ? 'Skipped (Credit Saved)'
                                          : (isDelivered
                                              ? 'Delivered'
                                              : 'Lunch Box • 12:30 PM'),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isSkipped
                                            ? Colors.redAccent
                                            : (isDelivered ? Colors.green : AppColors.secondaryText),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUpcoming && isActive)
                                GestureDetector(
                                  onTap: state.isSkipping
                                      ? null
                                      : () async {
                                          final occId = day.occurrenceId ?? 'occ_${day.date.millisecondsSinceEpoch}';
                                          await context.read<SubscriptionCubit>().skipOccurrence(
                                            subscriptionId: sub.id,
                                            occurrenceId: occId,
                                            date: day.date,
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.8),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      'Skip Meal',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // ── Delivery Tip Card ──────────────────────────────────────
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
                          'DELIVERY TIP',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Going out of town? Tap "Skip Meal" on specific calendar days or "Pause Plan" to freeze delivery without losing your credits.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.secondaryText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
      );
      },
    ),
  );
  }

  void _showPlanDetailsModal(BuildContext context, dynamic sub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final plan = sub.plan;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.name.toString(),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sub.status.toString().toUpperCase() == 'ACTIVE'
                          ? AppColors.greenLight
                          : AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sub.status.toString(),
                      style: TextStyle(
                        color: sub.status.toString().toUpperCase() == 'ACTIVE' ? AppColors.greenText : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Plan ID: #${sub.id.toString().length > 8 ? sub.id.toString().substring(sub.id.toString().length - 8).toUpperCase() : sub.id}',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 11.sp),
              ),
              const Divider(color: AppColors.border, height: 32),
              _buildDetailRow('Total Meals', '${plan.totalMeals} Meals'),
              const SizedBox(height: 12),
              _buildDetailRow('Remaining Meals', '${sub.remainingMeals} Meals'),
              const SizedBox(height: 12),
              _buildDetailRow('Plan Duration', '${plan.durationDays} Days'),
              const SizedBox(height: 12),
              _buildDetailRow('Price per Meal', '₹${plan.pricePerMeal.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _buildDetailRow('Total Amount', '₹${plan.totalPlanPrice.toStringAsFixed(0)}'),
              if (plan.deliveryDays is List && (plan.deliveryDays as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Delivery Days', (plan.deliveryDays as List).join(', ')),
              ],
              if (plan.benefits is List && (plan.benefits as List).isNotEmpty) ...[
                const Divider(color: AppColors.border, height: 32),
                Text(
                  'Included Benefits',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(plan.benefits as List).map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.toString(),
                              style: TextStyle(color: AppColors.primaryText, fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryGoldButton(
                  text: 'Close',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.secondaryText, fontSize: 12.sp)),
        Text(value, style: TextStyle(color: AppColors.primaryText, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
