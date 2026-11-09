import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/config/injection_container.dart';
import 'package:restaurantdashboard/core/theme/app_theme.dart';
import 'package:restaurantdashboard/core/theme/cubit/theme_cubit.dart';
import 'package:restaurantdashboard/core/theme/cubit/theme_state.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_cubit.dart';

import 'features/auth/presentation/providers/AuthProvider.dart';
import 'features/auth/presentation/screens/SplashScreen.dart';
import 'Services/ResturantService.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load skipped/failed: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initInjection();
  await sl<ThemeCubit>().loadTheme();

  final restaurantService = RestaurantService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => RestaurantProvider(restaurantService),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sl<ThemeCubit>()),
          BlocProvider.value(value: sl<NotificationCubit>()),
          BlocProvider.value(value: sl<MenuCubit>()),
          BlocProvider.value(value: sl<DashboardCubit>()),
          BlocProvider.value(value: sl<OrdersCubit>()),
          BlocProvider.value(value: sl<ReportsCubit>()),
          BlocProvider.value(value: sl<ReviewsCubit>()),
          BlocProvider.value(value: sl<ProfileCubit>()),
          BlocProvider.value(value: sl<MartCategoriesCubit>()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Restaurant Dashboard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeState.themeMode,
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: const [
                  Breakpoint(start: 0, end: 450, name: MOBILE),
                  Breakpoint(start: 451, end: 800, name: TABLET),
                  Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                ],
              ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
