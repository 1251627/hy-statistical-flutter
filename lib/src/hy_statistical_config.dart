class HyStatisticalConfig {
  final String apiKey;
  final String serverUrl;
  final int flushInterval;
  final int flushSize;
  final int maxRetries;
  final bool enableLog;

  /// [serverUrl] 必填，例如 https://collect.your-domain.com/api/v1
  /// 业务方在每次集成时显式声明，避免误把开发地址带到生产。
  const HyStatisticalConfig({
    required this.apiKey,
    required this.serverUrl,
    this.flushInterval = 10,
    this.flushSize = 50,
    this.maxRetries = 3,
    this.enableLog = false,
  });
}
