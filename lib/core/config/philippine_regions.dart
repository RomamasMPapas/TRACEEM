/// Philippine Regions Configuration
/// This file contains region-specific data for the TRACE EM application
library;

class PhilippineRegion {
  final String code;
  final String name;
  final String capital;
  final double centerLat;
  final double centerLng;
  final double swLat; // Southwest bound
  final double swLng;
  final double neLat; // Northeast bound
  final double neLng;

  const PhilippineRegion({
    required this.code,
    required this.name,
    required this.capital,
    required this.centerLat,
    required this.centerLng,
    required this.swLat,
    required this.swLng,
    required this.neLat,
    required this.neLng,
  });
}

class PhilippineRegions {
  static const region7 = PhilippineRegion(
    code: 'Region 7',
    name: 'Central Visayas',
    capital: 'Cebu City',
    centerLat: 10.3157,
    centerLng: 123.8854,
    swLat: 9.5,
    swLng: 123.0,
    neLat: 11.5,
    neLng: 124.5,
  );

  static const ncr = PhilippineRegion(
    code: 'NCR',
    name: 'National Capital Region',
    capital: 'Manila',
    centerLat: 14.5995,
    centerLng: 120.9842,
    swLat: 14.35,
    swLng: 120.85,
    neLat: 14.85,
    neLng: 121.15,
  );

  static const region3 = PhilippineRegion(
    code: 'Region 3',
    name: 'Central Luzon',
    capital: 'San Fernando',
    centerLat: 15.4817,
    centerLng: 120.7122,
    swLat: 14.5,
    swLng: 119.5,
    neLat: 16.5,
    neLng: 121.5,
  );

  static const region4a = PhilippineRegion(
    code: 'Region 4A',
    name: 'CALABARZON',
    capital: 'Calamba',
    centerLat: 14.2111,
    centerLng: 121.1634,
    swLat: 13.5,
    swLng: 120.5,
    neLat: 15.0,
    neLng: 122.0,
  );

  static const region11 = PhilippineRegion(
    code: 'Region 11',
    name: 'Davao Region',
    capital: 'Davao City',
    centerLat: 7.0731,
    centerLng: 125.6128,
    swLat: 5.5,
    swLng: 124.5,
    neLat: 8.5,
    neLng: 126.5,
  );

  static const allRegions = [region7, ncr, region3, region4a, region11];

  static PhilippineRegion? getRegionByCode(String code) {
    try {
      return allRegions.firstWhere((r) => r.code == code);
    } catch (e) {
      return region7; // Default to Region 7
    }
  }

  static List<String> getAllRegionCodes() {
    return allRegions.map((r) => r.code).toList();
  }

  /// Detect which Philippine region contains the given coordinates
  static PhilippineRegion? detectRegionFromCoordinates(
    double latitude,
    double longitude,
  ) {
    for (var region in allRegions) {
      // Check if coordinates fall within region bounds
      if (latitude >= region.swLat &&
          latitude <= region.neLat &&
          longitude >= region.swLng &&
          longitude <= region.neLng) {
        return region;
      }
    }
    // Return null if outside all known regions
    return null;
  }
}
