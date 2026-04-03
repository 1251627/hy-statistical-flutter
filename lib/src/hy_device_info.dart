import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class HyDeviceInfo {
  static const _deviceIdKey = 'hy_statistical_device_id';
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  String? _deviceId;

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    _deviceId = await _storage.read(key: _deviceIdKey);
    if (_deviceId != null) return _deviceId!;

    _deviceId = _uuid.v4();
    await _storage.write(key: _deviceIdKey, value: _deviceId!);
    return _deviceId!;
  }

  String get platform => Platform.isIOS ? 'ios' : 'android';

  String get osVersion => Platform.operatingSystemVersion;
}
