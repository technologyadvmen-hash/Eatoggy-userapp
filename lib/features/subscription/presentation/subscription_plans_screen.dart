import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/subscription_cubit.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SubscriptionCubit>();
      cubit.loadMySubscriptions();
      cubit.loadPlans();

      // If user has active subscriptions, default to tab 0 (My Subscriptions), else tab 1 (Explore Plans)
      if (cubit.state.mySubscriptions.isEmpty) {
        _tabController.index = 1;
      } else {
        _tabController.index = 0;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final intPrice = price.round();
    return intPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
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
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        if (state.plans.isNotEmpty && _selectedPlanId == null) {
          setState(() {
            _selectedPlanId = state.plans.first.id;
          });
        }
        if (state.actionMessage != null && state.actionMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionMessage!),
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final activeSubs = state.mySubscriptions;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              'Royal Subscriptions',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: () {
                  context.read<SubscriptionCubit>().loadMySubscriptions();
                  context.read<SubscriptionCubit>().loadPlans();
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                tooltip: 'Meal Calendar',
                onPressed: () => context.push('/my-subscription'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(6.h),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surface, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppColors.surface,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('My Subscriptions'),
                          if (activeSubs.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activeSubs.length}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Explore Plans'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: My Subscriptions ─────────────────────────────────
              _buildMySubscriptionsTab(context, state),

              // ── Tab 2: Explore Plans ────────────────────────────────────
              _buildExplorePlansTab(context, state),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 1: My Subscriptions Content
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMySubscriptionsTab(BuildContext context, SubscriptionState state) {
    if (state.isLoading && state.mySubscriptions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.mySubscriptions.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await context.read<SubscriptionCubit>().loadMySubscriptions();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: const Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.primary),
                  ),
                  SizedBox(height: 2.5.h),
                  Text(
                    'No Active Subscriptions',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Subscribe to daily gourmet meal boxes curated by royal chefs. Delivered hot to your doorstep every day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5.sp, height: 1.4),
                  ),
                  SizedBox(height: 3.5.h),
                  GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                    child: Container(
                      width: 60.w,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Explore Royal Plans',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await context.read<SubscriptionCubit>().loadMySubscriptions();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        itemCount: state.mySubscriptions.length,
        itemBuilder: (context, index) {
          final sub = state.mySubscriptions[index];
          final bool isActive = sub.status.toUpperCase() == 'ACTIVE';
          final int total = sub.plan.totalMeals > 0 ? sub.plan.totalMeals : 7;
          final int remaining = sub.remainingMeals;
          final double progress = total > 0 ? (total - remaining) / total : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 2.5.h),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.surface,
                width: isActive ? 1.2 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status badge & Sub ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF22C55E).withValues(alpha: 0.15) : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? const Color(0xFF22C55E) : AppColors.muted,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.pause_circle_outline,
                            size: 13,
                            color: isActive ? const Color(0xFF22C55E) : AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sub.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isActive ? const Color(0xFF22C55E) : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ID: ${sub.id.length > 8 ? sub.id.substring(sub.id.length - 8).toUpperCase() : sub.id}',
                      style: GoogleFonts.robotoMono(
                        color: AppColors.secondaryText,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),

                // Plan Name
                Text(
                  sub.plan.name,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 0.5.h),

                // Schedule details
                Text(
                  '${sub.plan.durationDays} Days Plan • Next delivery: ${_formatDate(sub.nextDelivery)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),

                // Progress Indicator (Meals consumed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meals Remaining: $remaining of $total',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% Done',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surface,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 2.5.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.read<SubscriptionCubit>().activateSubscription(sub);
                          context.read<SubscriptionCubit>().fetchSubscriptionTimeline(sub.id);
                          context.push('/my-subscription');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Meal Calendar & Manage',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: () {
                        context.read<SubscriptionCubit>().activateSubscription(sub);
                        if (isActive) {
                          context.read<SubscriptionCubit>().pauseSubscription();
                        } else {
                          context.read<SubscriptionCubit>().resumeSubscription();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surface, width: 1),
                        ),
                        child: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 2: Explore Plans Content
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExplorePlansTab(BuildContext context, SubscriptionState state) {
    if (state.isLoading && state.plans.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.plans.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await context.read<SubscriptionCubit>().loadPlans();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.lunch_dining_outlined, size: 60, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text(
                    'No meal plans available currently',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await context.read<SubscriptionCubit>().loadPlans();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effortless luxury meals, delivered daily',
              style: TextStyle(fontSize: 14.sp, color: AppColors.secondaryText),
            ),
            SizedBox(height: 2.h),
            ...state.plans.map((plan) {
              final bool isSelected = _selectedPlanId == plan.id;
              final bool isExtended = plan.durationDays >= 14;
              final String periodLabel = plan.durationDays > 0 ? '/${plan.durationDays} days' : '/plan';
              final String subtitleText = plan.benefits.isNotEmpty
                  ? plan.benefits.first
                  : '${plan.durationDays} Days Gourmet Subscription';

              return GestureDetector(
                onTap: () => setState(() => _selectedPlanId = plan.id),
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.5.h),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      width: isSelected ? 1.2 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExtended
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isExtended ? AppColors.primary : Colors.green,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              isExtended ? 'POPULAR • ${plan.durationDays} DAYS' : '${plan.durationDays} DAYS PASS',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isExtended ? AppColors.primary : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitleText,
                        style: TextStyle(fontSize: 14.5.sp, color: AppColors.secondaryText, height: 1.3),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${_formatPrice(plan.totalPlanPrice)}',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                periodLabel,
                                style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                          Text(
                            '₹${plan.pricePerMeal.toStringAsFixed(0)} / meal',
                            style: TextStyle(fontSize: 14.5.sp, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                      if (plan.benefits.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'INCLUDES',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...plan.benefits.take(3).map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        color: AppColors.primaryText,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          if (isExtended) {
                            context.push('/customize-subscription', extra: plan);
                          } else {
                            context.push('/plan-detail', extra: plan);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              isExtended ? 'Customize & Subscribe' : 'View Plan Details',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
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
            }),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}
