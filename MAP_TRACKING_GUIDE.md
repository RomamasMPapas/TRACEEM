# Adding API Map Tracking to TRACE EM

This guide explains how to add real-time map tracking to your application using Google Maps and Firebase.

## Prerequisites

1.  **Google Maps API Key**: You must have a valid Google Maps API Key enabled for:
    *   Maps SDK for Android
    *   Maps SDK for iOS (if targeting iOS)
    *   Directions API (for drawing routes)

## Step 1: Add Google Maps Dependency

The `google_maps_flutter` package is already in your `pubspec.yaml`.

## Step 2: Configure Android Manifest

Open `android/app/src/main/AndroidManifest.xml` and add your API key:

```xml
<manifest ...>
    <application ...>
        <!-- Add this meta-data tag -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
```

## Step 3: Implement Live Tracking Logic

The `OrderTrackingScreen.dart` currently simulates movement. To use real API data:

1.  **Driver App Side**:
    *   The driver app needs to capture location updates (using `geolocator` package).
    *   Push these updates to Firestore: `await firestore.collection('orders').doc(orderId).update({'driverLocation': GeoPoint(lat, lng)})`.

2.  **User App Side (Your App)**:
    *   Listen to the Firestore document for location changes.

### Example Implementation

In `OrderTrackingScreen.dart`, replace the simulation timer with a stream:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    var data = snapshot.data!.data() as Map<String, dynamic>;
    GeoPoint driverLoc = data['driverLocation'];
    
    // Update Map Marker
    _updateDriverMarker(LatLng(driverLoc.latitude, driverLoc.longitude));
    
    return GoogleMap(...);
  }
)
```

## Step 4: Draw Route with Directions API

To draw the line on the map:

1.  Enable **Directions API** in Google Cloud Console.
2.  Make an HTTP request to get the route coordinates:
    `https://maps.googleapis.com/maps/api/directions/json?origin=...&destination=...&key=YOUR_API_KEY`
3.  Decode the polyline string from the response and add it to the `polylines` set in `GoogleMap`.

## Monitoring Firebase

To monitor your database:
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Navigate to **Firestore Database**.
3.  Create a collection named `orders`.
4.  Add documents manually or via the app.
5.  Watch real-time updates as you modify data in the console or app.
