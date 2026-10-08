import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_keys.dart';
import '../constants/app_routes.dart';
import '../services/storage_service.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/whats_new_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/otp_screen.dart';
import '../../features/location/presentation/location_permission_screen.dart';
import '../../features/location/presentation/select_location_screen.dart';
import '../../features/location/presentation/add_address_screen.dart';
import '../../features/location/presentation/saved_addresses_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/food_detail/presentation/food_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/payment/presentation/payment_screen.dart';
import '../../features/orders/presentation/order_success_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/write_review_screen.dart';
import '../../features/orders/presentation/my_reviews_screen.dart';
import '../../features/tracking/presentation/tracking_screen.dart';
import '../../features/subscription/presentation/subscription_plans_screen.dart';
import '../../features/subscription/presentation/plan_detail_screen.dart';
import '../../features/subscription/presentation/customize_subscription_screen.dart';
import '../../features/subscription/presentation/my_subscription_screen.dart';
import '../../features/subscription/presentation/subscription_calendar_screen.dart';
import '../../features/subscription/data/models/customer_subscription_model.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/presentation/ticket_detail_screen.dart';
import '../../shared/widgets/navigation_shell.dart';
import '../../shared/models/models.dart';
import '../../shared/models/dummy_data.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/subscription/presentation/subscription_checkout_screen.dart';
import '../../features/error/presentation/not_found_screen.dart';
import '../../features/error/presentation/no_internet_screen.dart';
import '../../features/error/presentation/force_update_screen.dart';
import '../../features/error/presentation/maintenance_screen.dart';
import '../../features/error/presentation/rate_limit_screen.dart';
import '../../features/error/presentation/security_screen.dart';
import '../../features/location/presentation/enable_gps_screen.dart';
import '../../features/profile/presentation/terms_screen.dart';
import '../../features/profile/presentation/privacy_policy_screen.dart';
import '../../features/profile/presentation/refund_policy_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get navigatorKey => _rootNavigatorKey;

  static CustomTransitionPage<void> _buildSlidePage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.toString()),
    redirect: (context, state) async {
      final loc = state.uri.path;
      final isPublicRoute = loc == AppRoutes.splash ||
          loc == AppRoutes.onboarding ||
          loc == AppRoutes.login ||
          loc == AppRoutes.otp ||
          loc == AppRoutes.terms ||
          loc == AppRoutes.privacy ||
          loc == AppRoutes.refund ||
          loc.startsWith('/error');

      if (isPublicRoute) return null;

      final prefs = await SharedPreferencesService.getInstance();
      final token = prefs.getString(AppKeys.accessToken);

      // If no active auth token exists, block guest browsing and redirect to login
      if (token == null || token.trim().isEmpty || token == 'null') {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = state.extra as String? ?? '9999999999';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.locationPermission,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectLocation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SelectLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.addAddress,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddAddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedAddresses,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: AppRoutes.subscription,
            builder: (context, state) => const SubscriptionPlansScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.menu,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MenuScreen(initialRestaurant: state.extra),
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final food = state.extra is FoodItem
              ? state.extra as FoodItem
              : DummyData.foodItems.first;
          return _buildSlidePage(
            child: FoodDetailScreen(food: food),
            state: state,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildSlidePage(
          child: const CartScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.offers,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OffersScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildSlidePage(
          child: const CheckoutScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: AppRoutes.payment,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          double amount = 0.0;
          String? checkoutSessionId;
          String? razorpayOrderId;
          String? razorpayKey;
          Address? address;

          if (state.extra is double) {
            amount = state.extra as double;
          } else if (state.extra is num) {
            amount = (state.extra as num).toDouble();
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
            checkoutSessionId = map['checkoutSessionId'] as String?;
            razorpayOrderId = map['razorpayOrderId'] as String?;
            razorpayKey = map['razorpayKey'] as String?;
            address = map['address'] as Address?;
          }

          return _buildSlidePage(
            child: PaymentScreen(
              amount: amount,
              checkoutSessionId: checkoutSessionId,
              razorpayOrderId: razorpayOrderId,
              razorpayKey: razorpayKey,
              address: address,
            ),
            state: state,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final order = state.extra as Order;
          return _buildSlidePage(
            child: OrderSuccessScreen(order: order),
            state: state,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          if (state.extra is Order) {
            return OrderDetailsScreen(order: state.extra as Order);
          }
          final orderId = state.extra?.toString() ?? 'EAT-1001';
          return OrderDetailsScreen(
            order: Order(
              id: orderId,
              items: const [],
              subtotal: 0,
              discount: 0,
              deliveryFee: 0,
              total: 0,
              address: const Address(
                id: 'addr_default',
                name: 'Delivery Address',
                flatHouse: 'Apartment',
                street: 'Local Street',
                landmark: '',
                city: 'Local',
                pincode: '',
                type: 'Home',
              ),
              status: 'Active',
              orderTime: DateTime.now(),
              eta: '30-40 mins',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.writeReview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final order = state.extra as Order;
          return WriteReviewScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.tracking,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          Widget screen;
          if (state.extra is Order) {
            screen = TrackingScreen(order: state.extra as Order);
          } else if (state.extra is String) {
            screen = TrackingScreen(orderId: state.extra as String);
          } else {
            screen = const TrackingScreen();
          }
          return _buildSlidePage(child: screen, state: state);
        },
      ),
      GoRoute(
        path: AppRoutes.planDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = state.extra as SubscriptionPlan;
          return PlanDetailScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.customizeSubscription,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = state.extra as SubscriptionPlan;
          return CustomizeSubscriptionScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.mySubscription,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MySubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionCalendar,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final Subscription subscription = extra is Subscription
              ? extra
              : (extra is CustomerSubscriptionModel
                  ? extra.toSubscriptionEntity()
                  : Subscription(
                      id: 'sub_default',
                      plan: const SubscriptionPlan(
                        id: 'plan_default',
                        name: 'Maharaja Royal Thali Plan',
                        pricePerMeal: 150,
                        totalMeals: 7,
                        durationDays: 7,
                        deliveryDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                        benefits: ['Chef curated meals', 'Free delivery'],
                      ),
                      status: 'Active',
                      remainingMeals: 7,
                      nextDelivery: DateTime.now().add(const Duration(days: 1)),
                      schedule: const [],
                    ));
          return SubscriptionCalendarScreen(subscription: subscription);
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionCheckout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final subscription = state.extra as Subscription;
          return SubscriptionCheckoutScreen(subscription: subscription);
        },
      ),
      GoRoute(
        path: AppRoutes.support,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ticket = state.extra as SupportTicket;
          return TicketDetailScreen(ticket: ticket);
        },
      ),
      GoRoute(
        path: AppRoutes.myReviews,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.noInternet,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => NoInternetScreen(
          onRetry: state.extra as VoidCallback?,
        ),
      ),
      GoRoute(
        path: AppRoutes.forceUpdate,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForceUpdateScreen(),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final Map<String, dynamic>? args = state.extra as Map<String, dynamic>?;
          return MaintenanceScreen(
            message: args?['message'] as String?,
            estimatedTime: args?['estimatedTime'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.rateLimit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RateLimitScreen(
          onRetry: state.extra as VoidCallback?,
        ),
      ),
      GoRoute(
        path: AppRoutes.security,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.enableGps,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnableGpsScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.refund,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RefundPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.whatsNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WhatsNewScreen(),
      ),
    ],
  );
}
