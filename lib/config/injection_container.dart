import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:restaurantdashboard/Services/firebase_storage_service.dart';
import 'package:restaurantdashboard/core/theme/cubit/theme_cubit.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:restaurantdashboard/features/menu/data/datasources/items_excel_service.dart';
import 'package:restaurantdashboard/features/menu/data/datasources/menu_service.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:restaurantdashboard/features/orders/data/datasources/OrdersService.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:restaurantdashboard/features/reviews/data/datasources/RestaurantReviewService.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_cubit.dart';

final sl = GetIt.instance;

Future<void> initInjection() async {
  // External
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(
    () => firebase_auth.FirebaseAuth.instance,
  );
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Core
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<NotificationCubit>(() => NotificationCubit());
  sl.registerLazySingleton<FirebaseStorageService>(
    () => FirebaseStorageService(storage: sl()),
  );

  // Menu feature
  sl.registerLazySingleton<ItemsExcelService>(() => ItemsExcelService());
  sl.registerLazySingleton<MenuService>(
    () => MenuService(
      firestore: sl(),
      auth: sl(),
      storageService: sl(),
    ),
  );
  sl.registerLazySingleton<MenuCubit>(() => MenuCubit(sl()));

  // Dashboard feature
  sl.registerLazySingleton<DashboardCubit>(() => DashboardCubit());

  // Orders feature
  sl.registerLazySingleton<OrdersService>(
    () => OrdersService(firestore: sl()),
  );
  sl.registerLazySingleton<OrdersCubit>(() => OrdersCubit(sl()));

  // Reports feature
  sl.registerLazySingleton<ReportsCubit>(() => ReportsCubit());

  // Reviews feature
  sl.registerLazySingleton<RestaurantReviewService>(
    () => RestaurantReviewService(firestore: sl()),
  );
  sl.registerLazySingleton<ReviewsCubit>(() => ReviewsCubit(sl()));

  // Profile feature
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit());

  // Mart categories feature
  sl.registerLazySingleton<MartCategoriesCubit>(() => MartCategoriesCubit());
}
