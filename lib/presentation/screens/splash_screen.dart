import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _navigationTimer;
  AuthState? _currentAuthState;

  @override
  void initState() {
    super.initState();

    // Fire auth check
    context.read<AuthBloc>().add(AuthCheckRequested());

    // Log analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'splash_screen_viewed',
      parameters: {'screen_name': 'splash'},
    );

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() => setState(() {}));
    _controller.forward();

    // Start navigation timer
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _navigateToNext(_currentAuthState ?? AuthInitial());
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext(AuthState state) {
    if (!mounted) return;

    _navigationTimer?.cancel();

    Widget nextScreen;
    if (state is AuthAuthenticated) {
      nextScreen = state.user.role == 'admin'
          ? AdminHomeScreen(admin: state.user)
          : HomeScreen(user: state.user);
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _currentAuthState = state;
        // If the timer already finished, navigate immediately when state arrives
        if (_navigationTimer != null && !_navigationTimer!.isActive) {
          _navigateToNext(state);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4C8CFF),
        body: GestureDetector(
          onTap: () => _navigateToNext(_currentAuthState ?? AuthInitial()),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_shipping,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'TRACE EM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                // Progress Bar with Arrow
                Container(
                  width: 250,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: _animation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFF4C8CFF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF4C8CFF),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '(SPLASH SCREEN ARROW WOULD MOVE ALONG SIDE THE BAR UNTIL ITS FULL)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
