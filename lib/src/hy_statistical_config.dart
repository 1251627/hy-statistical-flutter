class HyStatisticalConfig {
  final String apiKey;
  final String serverUrl;
  final int flushInterval;
  final int flushSize;
  final int maxRetries;
  final bool enableLog;

  /// 启用广告归因：开启后 SDK 会在你的 App 进程内读取 IDFA / IDFV / PAID（iOS）
  /// 并随事件流上报到你自己配置的 serverUrl。**SDK 作者不接触任何用户数据**。
  /// 启用前请在 App 隐私政策中声明读取上述设备字段及用途。
  ///
  /// Android 端 v0.3.0 暂不采集（OAID 依赖业务方接入额外 SDK，留待后续版本）。
  final bool enableAdAttribution;

  /// [serverUrl] 必填，例如 https://collect.your-domain.com/api/v1
  /// 业务方在每次集成时显式声明，避免误把开发地址带到生产。
  const HyStatisticalConfig({
    required this.apiKey,
    required this.serverUrl,
    this.flushInterval = 10,
    this.flushSize = 50,
    this.maxRetries = 3,
    this.enableLog = false,
    this.enableAdAttribution = false,
  });
}
