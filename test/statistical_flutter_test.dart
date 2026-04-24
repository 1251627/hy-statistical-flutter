import 'package:flutter_test/flutter_test.dart';
import 'package:hy_statistical_flutter/statistical_flutter.dart';

void main() {
  test('HyStatisticalConfig has correct defaults', () {
    const config = HyStatisticalConfig(apiKey: 'test_key');
    expect(config.apiKey, 'test_key');
    expect(config.serverUrl, 'http://192.168.9.85:3000/api/v1');
    expect(config.flushInterval, 10);
    expect(config.flushSize, 50);
    expect(config.maxRetries, 3);
    expect(config.enableLog, false);
  });
}
