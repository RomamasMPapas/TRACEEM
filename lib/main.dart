import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/order_bloc.dart';
import 'presentation/screens/splash_screen.dart';
import 'infrastructure/services/tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();

  if (!kIsWeb) {
    // Background tracking is not supported on Web, and shouldn't block startup
    TrackingService.initializeService();
  }

  runApp(const MyApp());
}

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
