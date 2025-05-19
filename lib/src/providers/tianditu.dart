import 'dart:async';
import 'package:geolocator_cn/src/types.dart';

class LocationServiceProviderTianditu extends LocationServiceProvider {
  @override
  String name = 'tianditu';

  static bool inited = false;

  String androidKey = '';
  String iosKey = '';


  Map<String, Object>? _lastResult;

  @override
  LocationServiceProviderTianditu(this.androidKey, this.iosKey);

  @override
  setKey({String androidKey = '', String iosKey = ''}) {
    androidKey = androidKey;
    iosKey = iosKey;
  }

  _init() async {
    if (inited) {
      return;
    }

    assert(androidKey.isNotEmpty, '$name: android key is empty');
    // assert(iosKey.isNotEmpty, '$name: ios key is empty');
    inited = true;
  }

  @override
  Future<LocationData> getLocation() async {
    _init();

    Completer c = Completer();
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_lastResult?['latitude'] != null &&
          _lastResult?['longitude'] != null) {
        timer.cancel();
        c.complete(_lastResult);
      }
    });

    await c.future;

    return LocationData(
        latitude: double.tryParse("${_lastResult?['latitude']}") ?? 0,
        longitude: double.tryParse("${_lastResult?['longitude']}") ?? 0,
        accuracy: double.tryParse("${_lastResult?['accuracy']}") ?? 0,
        crs: CRS.gcj02,
        provider: name,
        address: "${_lastResult?['address']}");
  }

}
