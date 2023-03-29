import 'dart:convert';
import 'dart:math';

/// Geographic coordinate system
enum CRS {
  /// international coordinate
  wgs84,

  /// in China, amap coordinate
  gcj02,

  /// in China, baidu map coordinate
  bd09,

  /// not set
  unknown
}

/// precision convertor for double
extension Precision on double {
  double toPrecision(int fractionDigits) {
    var mod = pow(10, fractionDigits.toDouble()).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

/// The response object of [GeolocatorCN.getLocation] and [GeolocatorCN.onLocationChanged]
class LocationData {
  //是否有权限
  final bool hasPermission;
  /// The latitude of the location
  final double latitude;

  /// Longitude of the location
  final double longitude;

  /// the crs of this coordinate
  final CRS crs;

  /// The name of the provider that generated this data.
  final String provider;

  final String address;

  /// accuracy
  final double accuracy;

  /// time
  final int timestamp;

  factory LocationData(
      {bool hasPermission = true,
      double latitude = 0.0,
      double longitude = 0.0,
      CRS crs = CRS.unknown,
      String provider = '',
      String address = '',
      double accuracy = 500,
      int timestamp = 0}) {
    return LocationData._(
        hasPermission,
        latitude.toPrecision(6),
        longitude.toPrecision(6),
        crs,
        provider,
        address,
        accuracy.toPrecision(1),
        DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  LocationData._(this.hasPermission,this.latitude, this.longitude, this.crs, this.provider,this.address,
      this.accuracy, this.timestamp);

  factory LocationData.fromMap(Map<String, dynamic> dataMap) {
    return LocationData(
        hasPermission: dataMap['hasPermission'],
        latitude: dataMap['latitude'],
        longitude: dataMap['longitude'],
        crs: dataMap['crs'],
        provider: dataMap['provider'],
        address: dataMap['address'],
        accuracy: dataMap['accuracy'],
        timestamp: dataMap['timestamp']);
  }

  Map<String, dynamic> toMap() {
    return {
      'hasPermission': hasPermission,
      'latitude': latitude,
      'longitude': longitude,
      'crs': crs.toString().split('.').last,
      'provider': provider,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp
    };
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert(toMap());

  @override
  String toString() => toMap().toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          crs == other.crs &&
          address == other.address;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ crs.hashCode;

  bool isSuccess() {
    return true;
  }

  bool hasAddress() {
    return address.isNotEmpty;
  }
}

abstract class LocationServiceProvider {
  late String name;
  late bool enable = true;

  LocationServiceProvider();

  bool isEnable(){
    return enable;
  }

  /// Returns the current location of the device.
  Future<LocationData> getLocation();



  setKey({String androidKey = '', String iosKey = ''});
}
