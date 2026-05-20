import 'package:flutter_test/flutter_test.dart';
import 'package:hy_statistical_flutter/statistical_flutter.dart';
import 'package:hy_statistical_flutter/src/hy_ad_fingerprint.dart';

void main() {
  test('HyStatisticalConfig has correct defaults', () {
    const config = HyStatisticalConfig(
      apiKey: 'test_key',
      serverUrl: 'https://example.test/api/v1',
    );
    expect(config.apiKey, 'test_key');
    expect(config.serverUrl, 'https://example.test/api/v1');
    expect(config.flushInterval, 10);
    expect(config.flushSize, 50);
    expect(config.maxRetries, 3);
    expect(config.enableLog, false);
    expect(config.enableAdAttribution, false);
  });

  test('HyStatisticalConfig passes through enableLog', () {
    const config = HyStatisticalConfig(
      apiKey: 'k',
      serverUrl: 'https://example.test/api/v1',
      enableLog: true,
    );
    expect(config.enableLog, true);
  });

  test('HyStatisticalConfig enableAdAttribution explicitly opt-in', () {
    const config = HyStatisticalConfig(
      apiKey: 'k',
      serverUrl: 'https://example.test/api/v1',
      enableAdAttribution: true,
    );
    expect(config.enableAdAttribution, true);
  });

  group('HyAdFingerprintData', () {
    test('isUsable false when all identifiers empty', () {
      const fp = HyAdFingerprintData(os: 'ios', idfa: '', idfv: '', paid: '');
      expect(fp.isUsable, false);
    });

    test('isUsable true when any identifier non-empty', () {
      expect(
        const HyAdFingerprintData(os: 'ios', idfa: 'aaa', idfv: '', paid: '').isUsable,
        true,
      );
      expect(
        const HyAdFingerprintData(os: 'ios', idfa: '', idfv: 'bbb', paid: '').isUsable,
        true,
      );
      expect(
        const HyAdFingerprintData(os: 'ios', idfa: '', idfv: '', paid: 'ccc').isUsable,
        true,
      );
    });

    test('toUploadPayload omits empty fields, always includes os', () {
      const fp = HyAdFingerprintData(
        os: 'ios',
        idfa: 'aaaa-bbbb-cccc',
        idfv: '',
        paid: 'md5a-md5b-md5c',
      );
      final payload = fp.toUploadPayload();
      expect(payload['os'], 'ios');
      expect(payload['idfa'], 'aaaa-bbbb-cccc');
      expect(payload.containsKey('idfv'), false);
      expect(payload['paid'], 'md5a-md5b-md5c');
    });

    test('toUploadPayload only os when nothing else', () {
      const fp = HyAdFingerprintData(os: 'android', idfa: '', idfv: '', paid: '');
      expect(fp.toUploadPayload(), {'os': 'android'});
    });
  });
}
