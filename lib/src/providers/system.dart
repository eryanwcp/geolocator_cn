import 'package:flutter/foundation.dart';
import 'package:geolocator_cn/src/types.dart';
import 'package:geolocator/geolocator.dart';

class LocationServiceProviderSystem extends LocationServiceProvider {
  @override
  String name = 'system';



  LocationServiceProviderSystem();

  @override
  setKey({String androidKey = '', String iosKey = ''}) {}

  @override
  Future<LocationData> getLocation() async {
    Position? position;

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 100,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10)
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else if (kIsWeb) {
      locationSettings = WebSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 100,
        maximumAge: Duration(minutes: 10),
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 100,
      );
    }

    try {
      if(!kIsWeb){
        position = await Geolocator.getLastKnownPosition(
            forceAndroidLocationManager: true);
      }

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings);
    } catch (e) {
      print(e);
    }
    if(null == position){
      print("Unknown position.");
    }

    return LocationData(
        latitude: position?.latitude ?? 0,
        longitude: position?.longitude ?? 0,
        crs: CRS.wgs84,
        provider: name,
        address: '',
        accuracy: position?.accuracy ?? 0);
  }
}
