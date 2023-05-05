import 'dart:async';
import 'dart:io';

import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart'
    show BMFLog, BMFMapSDK, BMF_COORD_TYPE;
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:geolocator_cn/src/types.dart';

class LocationServiceProviderBaidu extends LocationServiceProvider {
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
        accuracy: _lastResult?.radius ?? 0,
        address: _lastResult?.address ?? '');
  }

  void _init() {
    if (inited) {
      return;
    }
    /// 设置是否隐私政策
    /// 隐私政策官网链接：https://lbsyun.baidu.com/index.php?title=openprivacy
    /// 通知用户之后根据用户选择进行赋值
    _locationPlugin.setAgreePrivacy(true);
    BMFMapSDK.setAgreePrivacy(true);

    /// 设置ios端ak, android端ak可以直接在清单文件中配置
    if (Platform.isIOS) {
      /// 设置ios端ak, android端ak可以直接在清单文件中配置
      _locationPlugin.authAK(iosKey);
      BMFMapSDK.setApiKeyAndCoordType(iosKey, BMF_COORD_TYPE.BD09LL);
    }else if (Platform.isAndroid) {
      // Android 目前不支持接口设置Apikey,
      // 请在主工程的Manifest文件里设置，详细配置方法请参考官网(https://lbsyun.baidu.com/)demo
      BMFMapSDK.setCoordType(BMF_COORD_TYPE.BD09LL);
    }

    _locationPlugin.getApiKeyCallback(callback: (String result) {
      String str = result;
      print('百度地图鉴权结果：' + str);
    });


    ///单次定位时如果是安卓可以在内部进行判断调用连续定位
    if (Platform.isIOS) {
      ///接受定位回调
      _locationPlugin.singleLocationCallback(callback: (BaiduLocation result) {
        if (result.latitude != null && result.longitude != null) {
          _lastResult = result;
          _stopLocation();
        }
      });
    } else if (Platform.isAndroid) {
      ///接受定位回调
      _locationPlugin.seriesLocationCallback(callback: (BaiduLocation result) {
        if (result.latitude != null && result.longitude != null) {
          _lastResult = result;
          _stopLocation();
        }
      });
    }


    inited = true;
  }

  /// 启动定位
  void _startLocation() {
    try {
      _setLocOption();
      // _locationPlugin.startLocation();
      if (Platform.isIOS) {
       _locationPlugin.singleLocation({'isReGeocode': true, 'isNetworkState': true});
      } else if (Platform.isAndroid) {
        _locationPlugin.startLocation();
      }
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
    BaiduLocationAndroidOption androidOption = BaiduLocationAndroidOption(coordType: BMFLocationCoordType.bd09ll,
    locationMode: BMFLocationMode.hightAccuracy,
    isNeedAddress: true,
    isNeedAltitude: true,
    isNeedLocationPoiList: false,
    isNeedNewVersionRgc: true,
    openGps: true,
    locationPurpose: BMFLocationPurpose.signIn,
    scanspan: 1000);

    Map androidMap = androidOption.getMap();

    /// ios 端设置定位参数
    BaiduLocationIOSOption iosOption = BaiduLocationIOSOption(coordType: BMFLocationCoordType.bd09ll,
        BMKLocationCoordinateType: 'BMKLocationCoordinateTypeBMK09LL',
        desiredAccuracy: BMFDesiredAccuracy.best);
    iosOption.setIsNeedNewVersionRgc(true); // 设置是否需要返回最新版本rgc信息
    iosOption.setActivityType(BMFActivityType.fitness); // 设置应用位置类型
    iosOption.setLocationTimeout(10); // 设置位置获取超时时间
    iosOption.setReGeocodeTimeout(10); // 设置获取地址信息超时时间
    iosOption.setDistanceFilter(0); // 设置定位最小更新距离
    iosOption.setAllowsBackgroundLocationUpdates(false); // 是否允许后台定位
    iosOption.setPauseLocUpdateAutomatically(true); //  定位是否会被系统自动暂停

    Map iosMap = iosOption.getMap();

    _locationPlugin.prepareLoc(androidMap, iosMap);
  }
}
