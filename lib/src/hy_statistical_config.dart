class HyStatisticalConfig {
  final String apiKey;
  final String serverUrl;
  final int flushInterval;
  final int flushSize;
  final int maxRetries;

  const HyStatisticalConfig({
    required this.apiKey,
    this.serverUrl = 'http://192.168.9.53:3000/api/v1',
    this.flushInterval = 10,
    this.flushSize = 50,
    this.maxRetries = 3,
  });
}
