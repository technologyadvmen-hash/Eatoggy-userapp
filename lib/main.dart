import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/app_repository.dart';
import 'core/services/storage_service.dart';
import 'features/home/cubit/home_cubit.dart';
import 'features/cart/cubit/cart_cubit.dart';
import 'features/subscription/cubit/subscription_cubit.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';
import 'features/splash/cubit/splash_cubit.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'features/menu/cubit/menu_cubit.dart';
import 'features/error/presentation/crash_screen.dart';

void main() async {
  // Ensure Flutter engine and native binary bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against unhandled platform errors and UI crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🚨 Flutter UI Error: ${details.exceptionAsString()}");
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CrashScreen(errorDetails: details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🚨 Unhandled Asynchronous Platform Error: $error\n$stack");
    return true; // Prevents app termination on uncaught async errors
  };

  // Pre-initialize SharedPreferences once at startup to prevent concurrent initialization race conditions
  try {
    await SharedPreferencesService.init();
  } catch (e) {
    debugPrint("⚠️ Warning initializing SharedPreferences: $e");
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final repository = MockAppRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SplashCubit()),
        BlocProvider(create: (_) => OnboardingCubit()),
        BlocProvider(create: (_) => HomeCubit(repository)),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => SubscriptionCubit(repository)),
        BlocProvider(create: (_) => OrderCubit()),
        BlocProvider(create: (_) => MenuCubit()),
      ],
      child: const EatoggyApp(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
GlobalKey<NavigatorState> get navigatorKey => AppRouter.navigatorKey;

class EatoggyApp extends StatelessWidget {
  const EatoggyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp.router(
          title: 'EATOGGY',
          theme: AppTheme.lightTheme,
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
