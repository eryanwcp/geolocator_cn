import 'package:geolocator_cn/src/types.dart';
import 'package:geolocator_web/geolocator_web.dart';

class LocationServiceProviderWeb extends LocationServiceProvider {
  @override
  String name = 'web';

  static const String _locationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _permissionDeniedMessage = 'Permission denied.';
  static const String _permissionDeniedForeverMessage =
      'Permission denied forever.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  LocationServiceProviderWeb();

  @override
  setKey({String androidKey = '', String iosKey = ''}) {}

  @override
  Future<LocationData> getLocation() async {
    Position? position;
    bool hasPermission = false;
    try {
      hasPermission = await _handlePermission();
      if (hasPermission) {
        position ??= await _geolocatorPlatform.getCurrentPosition();
      }
    } catch (e) {
      print(e);
    }

    return LocationData(
        hasPermission: hasPermission,
        latitude: position?.latitude ?? 0,
        longitude: position?.longitude ?? 0,
        crs: CRS.wgs84,
        provider: name,
        accuracy: position?.accuracy ?? 0);
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      print(_locationServicesDisabledMessage);
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        print(_permissionDeniedMessage);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(_permissionDeniedForeverMessage);
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

}
