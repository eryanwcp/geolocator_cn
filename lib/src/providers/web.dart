import 'package:geolocator/geolocator.dart';
import 'package:geolocator_cn/src/types.dart';
import 'package:location/location.dart' as mLocation;

class LocationServiceProviderWeb extends LocationServiceProvider {
  @override
  String name = 'web';


  LocationServiceProviderWeb();

  @override
  setKey({String androidKey = '', String iosKey = ''}) {}

  @override
  Future<LocationData> getLocation() async {
    Position? position;
    bool hasPermission = false;
    try {
      mLocation.Location location = mLocation.Location();
      hasPermission = await _handlePermission(location);
      if (hasPermission) {
        var locationData = await location.getLocation();
        position ??= Position.fromMap({
          'latitude': locationData.latitude ?? 0,
          'longitude': locationData.longitude ?? 0,
          'accuracy': locationData.accuracy ?? 0
        });
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

  Future<bool> _handlePermission(mLocation.Location location) async {
    bool _serviceEnabled;
    mLocation.PermissionStatus _permissionGranted;
    mLocation.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == mLocation.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != mLocation.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

}
