import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

    // The interval for updates (10 minutes)
    const updateInterval = Duration(minutes: 10);

    Timer.periodic(updateInterval, (timer) async {
      try {
        // 1. Get location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 2. Send to FastAPI
        // For Web, use localhost. For Android Emulator, use 10.0.2.2.
        final String baseUrl = const bool.fromEnvironment('dart.library.html')
            ? 'http://localhost:8000'
            : 'http://10.0.2.2:8000';

        final url = Uri.parse('$baseUrl/track');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': 'user_123', // This should be the real user ID
            'latitude': position.latitude,
            'longitude': position.longitude,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('Location updated successfully');
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
