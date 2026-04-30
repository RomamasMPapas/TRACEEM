import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/order_bloc.dart';
import 'presentation/screens/splash_screen.dart';

/// Application entry point.
/// Loads environment variables, initializes all dependencies via the injection container,
/// and launches the app. (Background tracking disabled as requested)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();

  // Background tracking service disabled to focus on the riding part
  // if (!kIsWeb) {
  //   TrackingService.initializeService();
  // }

  runApp(const MyApp());
}

/// The root widget of the TRACE EM application.
/// Sets up the [MultiBlocProvider] with [AuthBloc] and [OrderBloc], then loads the [SplashScreen].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<OrderBloc>()),
      ],
      child: MaterialApp(
        title: 'TRACE EM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
  }
}
