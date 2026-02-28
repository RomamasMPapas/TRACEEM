import 'package:geolocator/geolocator.dart';
import '../config/philippine_regions.dart';

/// Service for detecting user's current region based on GPS location
class LocationService {
  /// Check if location services are enabled and permissions are granted
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get the user's current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Detect which Philippine region the user is currently in
  static Future<PhilippineRegion?> detectCurrentRegion() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      return PhilippineRegions.detectRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('Error detecting region: $e');
      return null;
    }
  }

  /// Get region code from current location (returns null if detection fails)
  static Future<String?> detectCurrentRegionCode() async {
    final region = await detectCurrentRegion();
    return region?.code;
  }
}
