import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../firebase_options.dart';

/// Background service responsible for periodically sending the user's GPS location
/// to the TRACE EM tracking API while the app is running.
class TrackingService {
  /// Configures and starts the background tracking service for both Android and iOS.
  /// Sets up the notification channel and kicks off the service process.
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'TRACE EM Tracking',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  /// iOS-specific background handler called when the service runs in the background.
  /// Required entry-point for iOS background execution.
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main entry-point for the background service on both Android and iOS foreground.
  /// Runs a periodic timer every 10 minutes to fetch GPS location and send it to the tracking API.
  /// Also listens for a 'stopService' signal to gracefully shut down.
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Dotenv and Firebase in the background isolate
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // The interval for updates - Reduced for higher fidelity (e.g., 30 seconds)
    const updateInterval = Duration(seconds: 30);

    Timer.periodic(updateInterval, (timer) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('Tracking skipped: No user authenticated');
          return;
        }

        // 1. Get location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 2. Select URL based on Platform
        // In background service, we can't easily use kIsWeb, but we can check the environment
        final String baseUrl = (identical(0, 0.0)) // Heuristic for web in some contexts or check env
            ? dotenv.get('API_URL_WEB', fallback: 'http://localhost:8000')
            : dotenv.get('API_URL_ANDROID', fallback: 'http://10.0.2.2:8000');
        
        final url = Uri.parse('$baseUrl/track');


        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': user.uid,
            'latitude': position.latitude,
            'longitude': position.longitude,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint(
              'Location updated for ${user.uid}: ${position.latitude}, ${position.longitude}');
        } else {
          debugPrint('Failed to update location: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error in tracking service: $e');
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
}
