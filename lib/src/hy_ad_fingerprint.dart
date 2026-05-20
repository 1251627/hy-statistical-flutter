import 'dart:io';
import 'package:flutter/services.dart';

/// 跟 iOS native SDK 完全一致的指纹数据结构。
class HyAdFingerprintData {
  final String os; // "ios" / "android" / "unknown"
  final String idfa; // iOS only; "" if unauthorized
  final String idfv; // iOS only; "" if unavailable
  final String paid; // iOS only; 32-hex MD5 triple separated by "-"

  const HyAdFingerprintData({
    required this.os,
    required this.idfa,
    required this.idfv,
    required this.paid,
  });

  /// 至少有一个标识符非空时，才是有效指纹（可用于归因匹配）。
  bool get isUsable => idfa.isNotEmpty || idfv.isNotEmpty || paid.isNotEmpty;

  /// 用于随事件流上传给 backend 的 payload。空字段不上报。
  Map<String, dynamic> toUploadPayload() {
    final m = <String, dynamic>{'os': os};
    if (idfa.isNotEmpty) m['idfa'] = idfa;
    if (idfv.isNotEmpty) m['idfv'] = idfv;
    if (paid.isNotEmpty) m['paid'] = paid;
    return m;
  }
}

/// 调原生 iOS HyAdFingerprint 模块采集 IDFA / IDFV / PAID。
/// Android v0.3.0 暂不实现（OAID 依赖业务方接入额外 SDK）。
class HyAdFingerprint {
  static const _channel = MethodChannel('hy_statistical_flutter/ad_fingerprint');

  static Future<HyAdFingerprintData> collect() async {
    if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('collectAdFingerprint');
        if (result == null) return _emptyAndroidIos('ios');
        return HyAdFingerprintData(
          os: (result['os'] as String?) ?? 'ios',
          idfa: (result['idfa'] as String?) ?? '',
          idfv: (result['idfv'] as String?) ?? '',
          paid: (result['paid'] as String?) ?? '',
        );
      } on PlatformException {
        return _emptyAndroidIos('ios');
      } on MissingPluginException {
        // 业务方还在用旧版 SDK / pod 没装 / 测试环境无 plugin —— 返回空，事件流照常工作
        return _emptyAndroidIos('ios');
      }
    }
    // Android / 其他平台：v0.3.0 不采集
    return _emptyAndroidIos(Platform.isAndroid ? 'android' : 'unknown');
  }

  static HyAdFingerprintData _emptyAndroidIos(String os) {
    return HyAdFingerprintData(os: os, idfa: '', idfv: '', paid: '');
  }
}
