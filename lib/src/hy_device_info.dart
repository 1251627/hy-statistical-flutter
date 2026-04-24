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

  /// 归一化 OS 版本号，例如
  /// iOS:     'Version 26.3.1 (a) (Build 23D771330a)' → '26.3.1'
  /// Android: 'Linux 4.14.190 #1 SMP PREEMPT' → '4.14.190'
  /// 抽不到时回退到原始字符串。
  String get osVersion {
    final raw = Platform.operatingSystemVersion;
    final match = RegExp(r'\d+(?:\.\d+)+').firstMatch(raw);
    return match?.group(0) ?? raw;
  }
}
