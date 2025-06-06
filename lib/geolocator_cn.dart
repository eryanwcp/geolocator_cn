library geolocator_cn;

import 'dart:async';
import 'package:coordtransform_dart/coordtransform_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_cn/src/providers/tianditu.dart';
// import 'package:geolocator_cn/src/providers/web.dart';
import 'package:permission_handler/permission_handler.dart';
import 'src/providers/baidu.dart';
import 'src/providers/system.dart';
import 'src/providers/amap.dart';
import 'src/providers/ip.dart';
import 'src/types.dart';
export 'src/types.dart';

/// provider registry
class GeolocatorCNProviders {
  static Map<String, dynamic> config = {
    'baidu': {'ios': 'YOUR API KEY'},
    'amap': {'ios': 'YOUR API KEY', 'android': 'YOUR API KEY'},
    'tianditu': {'ios': 'YOUR API KEY', 'android': 'YOUR API KEY'},
  };

  static LocationServiceProviderSystem system = LocationServiceProviderSystem();
  static LocationServiceProviderBaidu baidu = LocationServiceProviderBaidu(config['baidu']['ios']);
  static LocationServiceProviderAmap amap = LocationServiceProviderAmap(config['amap']['android'], config['amap']['ios']);
  static LocationServiceProviderTianditu tianditu = LocationServiceProviderTianditu(config['tianditu']['android'], config['tianditu']['ios']);
  // static LocationServiceProviderWeb web = LocationServiceProviderWeb();
  static LocationServiceProviderIPaddr ip = LocationServiceProviderIPaddr();
  ///
  static int compareProviderCount = 2;
}

/// A service helper class that can use multiple location services at the same time.
class GeolocatorCN {
  List<LocationServiceProvider> providers;

  factory GeolocatorCN({List<LocationServiceProvider>? providers}) {
    return GeolocatorCN._(providers ??
        [
          GeolocatorCNProviders.system,
          GeolocatorCNProviders.baidu,
          GeolocatorCNProviders.amap
        ]);
  }

  GeolocatorCN._(this.providers);

  /// check if the location service is enabled, if not enabled, request permission
  Future<bool> hasPermission() async {
    PermissionStatus status = await Permission.location.request();

    return (status == PermissionStatus.granted);
  }

  /// get the current location
  Future<LocationData> getLocation({CRS crs = CRS.gcj02}) async {
    LocationData location = LocationData();
    Completer c = Completer();
    if(kIsWeb){
      // GeolocatorCNProviders.web.getLocation().then((value) {
      //   if (c.isCompleted != true) {
      //     c.complete(value);
      //   }
      // }).catchError((e) {
      //   print(e);
      // });
      GeolocatorCNProviders.system.getLocation().then((value) {
        if (c.isCompleted != true) {
          c.complete(value);
        }
      }).catchError((e) {
        print(e);
      });
      try {
        location = await c.future;
      } catch (e) {
        print(e);
        location = await GeolocatorCNProviders.ip.getLocation();
      }
    }else{
      if (await hasPermission() == true) {


        /// 哪个先返回有效结果就用哪个
        for (var provider in providers) {
          if(!provider.isEnable()){
            print("GPS服务不可用：${provider.name}");
          }else{
            provider.getLocation().then((value) {
              if (value.latitude != 0 && value.longitude != 0) {
                if (c.isCompleted != true) {
                  c.complete(value);
                }
              }
            }).catchError((e) {
              print(e);
            });
          }
        }

        try {
          location = await c.future;
        } catch (e) {
          print(e);
          location = await GeolocatorCNProviders.ip.getLocation();
        }
      } else {
        /// if we cat't get permission, we can only use the ip location api
        location = await GeolocatorCNProviders.ip.getLocation();
      }
    }



    /// transform the location to the specified crs and return
    LocationData ret = _transormCrs(location, location.crs, crs);
    print('GeolocatorCN->getLocation: $ret');

    return ret;
  }

  /// transform the location data from one crs to another
  LocationData _transormCrs(LocationData data, CRS from, CRS to) {
    if (data.crs != CRS.unknown &&
        from != to &&
        data.latitude != 0 &&
        data.longitude != 0) {
      var result = [data.longitude, data.latitude];
      if (from == CRS.wgs84 && to == CRS.gcj02) {
        result =
            CoordinateTransformUtil.wgs84ToGcj02(data.longitude, data.latitude);
      } else if (from == CRS.gcj02 && to == CRS.wgs84) {
        result =
            CoordinateTransformUtil.gcj02ToWgs84(data.longitude, data.latitude);
      } else if (from == CRS.wgs84 && to == CRS.bd09) {
        result =
            CoordinateTransformUtil.wgs84ToBd09(data.longitude, data.latitude);
      } else if (from == CRS.bd09 && to == CRS.wgs84) {
        result =
            CoordinateTransformUtil.bd09ToWgs84(data.longitude, data.latitude);
      } else if (from == CRS.gcj02 && to == CRS.bd09) {
        result =
            CoordinateTransformUtil.gcj02ToBd09(data.longitude, data.latitude);
      } else if (from == CRS.bd09 && to == CRS.gcj02) {
        result =
            CoordinateTransformUtil.bd09ToGcj02(data.longitude, data.latitude);
      }

      Map<String, dynamic> tmp = data.toMap();
      tmp['latitude'] = result[1];
      tmp['longitude'] = result[0];
      tmp['crs'] = to;

      return LocationData.fromMap(tmp);
    } else {
      return data;
    }
  }

  Future<LocationData> getNearestLocation({CRS crs = CRS.gcj02,double? longitude, double? latitude}) async {
    if(longitude == null || latitude == null){
      return getLocation(crs: crs);
    }
    LocationData location = LocationData();
    Completer c = Completer();
    if(kIsWeb){
      // GeolocatorCNProviders.web.getLocation().then((value) {
      //   if (c.isCompleted != true) {
      //     c.complete(value);
      //   }
      // }).catchError((e) {
      //   print(e);
      // });
      GeolocatorCNProviders.system.getLocation().then((value) {
        if (c.isCompleted != true) {
          c.complete(value);
        }
      }).catchError((e) {
        print(e);
      });
      try {
        location = await c.future;
      } catch (e) {
        print(e);
        location = await GeolocatorCNProviders.ip.getLocation();
      }
    }else{
      if (await hasPermission() == true) {
        List<LocationData> results = [];
        int enableCount = 0;
        /// 哪个先返回有效结果就用哪个
        for (var provider in providers) {
          if(!provider.isEnable()){
            print("GPS服务不可用：${provider.name}");
          }else{
            enableCount ++;
            provider.getLocation().then((value) {
              if (value.latitude != 0 && value.longitude != 0) {
                LocationData ret = _transormCrs(value, value.crs, crs);
                double distance = _getDistance(ret.longitude,ret.latitude,longitude,latitude);
                //减去偏移值
                distance = distance <= value.accuracy ? 0:distance - value.accuracy;

                value.distance = distance;

                results.add(value);
                print("${provider.name}:$distance");
              }
            }).catchError((e) {
              print(e);
            });
          }
        }

        Timer.periodic(const Duration(milliseconds: 200), (timer) {
          if(results.isNotEmpty && results.length >= (GeolocatorCNProviders.compareProviderCount > enableCount ? enableCount:GeolocatorCNProviders.compareProviderCount)){
            LocationData result = results.reduce((value, element) {
              return value.distance < element.distance ? value : element;
            });
            timer.cancel();
            c.complete(result);
          }
        });

        try {
          location = await c.future;
        } catch (e) {
          print(e);
          location = await GeolocatorCNProviders.ip.getLocation();
        }
      } else {
        /// if we cat't get permission, we can only use the ip location api
        location = await GeolocatorCNProviders.ip.getLocation();
      }
    }



    /// transform the location to the specified crs and return
    LocationData ret = _transormCrs(location, location.crs, crs);
    print('GeolocatorCN->getNearestLocation: $ret');

    return ret;
  }

  double _getDistance(double _longitudeForCalculation,
      double _latitudeForCalculation, double longitude, double latitude) {
    return Geolocator.distanceBetween(
      _latitudeForCalculation,
      _longitudeForCalculation,
      latitude,
      longitude,
    );
  }
}
