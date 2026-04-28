import 'package:flutter_test/flutter_test.dart';
import 'package:hy_statistical_flutter/statistical_flutter.dart';

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
  });

  test('HyStatisticalConfig passes through enableLog', () {
    const config = HyStatisticalConfig(
      apiKey: 'k',
      serverUrl: 'https://example.test/api/v1',
      enableLog: true,
    );
    expect(config.enableLog, true);
  });
}
