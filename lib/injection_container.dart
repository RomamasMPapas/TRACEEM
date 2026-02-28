import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/usecases/get_orders_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/signup_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'domain/usecases/check_auth_usecase.dart';
import 'infrastructure/repositories/auth_repository_impl.dart';
import 'infrastructure/repositories/order_repository_impl.dart';
import 'domain/usecases/logout_usecase.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/order_bloc.dart';

import 'firebase_options.dart';

final sl = GetIt.instance;

Future<void> init() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Fix for "FIRESTORE INTERNAL ASSERTION FAILED" on Web
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

    print('Firebase initialized successfully');

    // Initialize Firebase Analytics
    final analytics = FirebaseAnalytics.instance;
    sl.registerLazySingleton<FirebaseAnalytics>(() => analytics);
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthUseCase(sl()));
  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl());

  // Blocs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      signUpUseCase: sl(),
      updateProfileUseCase: sl(),
      checkAuthUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );
  sl.registerFactory(() => OrderBloc(getOrdersUseCase: sl()));
}
