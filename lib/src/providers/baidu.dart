import 'dart:async';
import 'dart:io';

import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:geolocator_cn/src/types.dart';

class LocationServiceProviderBaidu implements LocationServiceProvider {
  @override
  String name = 'baidu';

  static bool inited = false;

  /// baidu stuff
  String iosKey = '';
  BaiduLocation? _lastResult;
  static final LocationFlutterPlugin _locationPlugin = LocationFlutterPlugin();

  /// constructor
  @override
  LocationServiceProviderBaidu(this.iosKey);

  @override
  setKey({String androidKey = '', String iosKey = ''}) {}

  @override
  Future<LocationData> getLocation() async {
    _init();

    _startLocation();

    Completer c = Completer();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_lastResult?.latitude != null && _lastResult?.longitude != null) {
        timer.cancel();
        c.complete(_lastResult);
      }
    });

    await c.future;

    return LocationData(
        provider: name,
        latitude: _lastResult?.latitude ?? 0,
        longitude: _lastResult?.longitude ?? 0,
        crs: CRS.bd09,
        accuracy: _lastResult?.radius ?? 0);
  }

  void _init() {
    if (inited) {
      return;
    }

    /// 设置ios端ak, android端ak可以直接在清单文件中配置
    if (Platform.isIOS) {
      /// 设置ios端ak, android端ak可以直接在清单文件中配置
      _locationPlugin.authAK(iosKey);
    }

    _locationPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
      if (result.latitude != null && result.longitude != null) {
        _lastResult = result;
        _stopLocation();
      }
    });

    inited = true;
  }

  /// 启动定位
  void _startLocation() {
    try {
      _setLocOption();
      _locationPlugin.startLocation();
    } catch (e) {
      print(e);
    }
  }

  /// 停止定位
  void _stopLocation() {
    try {
      _locationPlugin.stopLocation();
    } catch (e) {
      print(e);
    }
  }

  /// 设置android端和ios端定位参数
  void _setLocOption() {
    /// android 端设置定位参数
    BaiduLocationAndroidOption androidOption = BaiduLocationAndroidOption(coordType: BMFLocationCoordType.bd09ll);
    androidOption.setIsNeedAltitude(false); // 设置是否需要返回海拔高度信息
    androidOption.setIsNeedAddress(false); // 设置是否需要返回地址信息
    androidOption.setIsNeedLocationPoiList(false); // 设置是否需要返回周边poi信息
    androidOption.setIsNeedNewVersionRgc(false); // 设置是否需要返回最新版本rgc信息
    androidOption.setIsNeedLocationDescribe(false); // 设置是否需要返回位置描述
    androidOption.setOpenGps(true); // 设置是否需要使用gps
    androidOption.setLocationMode(BMFLocationMode.hightAccuracy); // 设置定位模式
    androidOption.setScanspan(1000); // 设置发起定位请求时间间隔

    Map androidMap = androidOption.getMap();

    /// ios 端设置定位参数
    BaiduLocationIOSOption iosOption = BaiduLocationIOSOption(coordType: BMFLocationCoordType.bd09ll);
    iosOption.setIsNeedNewVersionRgc(true); // 设置是否需要返回最新版本rgc信息
    iosOption.setActivityType(BMFActivityType.fitness); // 设置应用位置类型
    iosOption.setLocationTimeout(10); // 设置位置获取超时时间
    iosOption
        .setDesiredAccuracy(BMFDesiredAccuracy.nearestTenMeters); // 设置预期精度参数
    iosOption.setReGeocodeTimeout(10); // 设置获取地址信息超时时间
    iosOption.setDistanceFilter(0); // 设置定位最小更新距离
    iosOption.setAllowsBackgroundLocationUpdates(false); // 是否允许后台定位
    iosOption.setPauseLocUpdateAutomatically(true); //  定位是否会被系统自动暂停

    Map iosMap = iosOption.getMap();

    _locationPlugin.prepareLoc(androidMap, iosMap);
  }
}
