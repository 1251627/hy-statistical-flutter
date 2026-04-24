# HyStatistical Flutter SDK

轻量级数据埋点 SDK：事件上报、批量发送、离线缓存、自动采集 App 生命周期事件。

## 安装

```yaml
# pubspec.yaml
dependencies:
  hy_statistical_flutter:
    git:
      url: https://github.com/1251627/hy-statistical-flutter.git
      ref: v0.1.4
```

```bash
flutter pub get
```

## 快速开始

```dart
import 'package:hy_statistical_flutter/statistical_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final info = await PackageInfo.fromPlatform();
  final userId = await loadLocalUserId();   // 你自己的 UUID 持久化

  await HyStatistical.initialize(
    config: HyStatisticalConfig(
      apiKey: 'your_api_key',
      enableLog: false,   // 开发期可以开
    ),
    appVersion: info.version,
    userId: userId,       // 可选；传入后首条 app_open 也带 user_id
  );

  runApp(MyApp());
}
```

## 上报事件

```dart
// 自定义事件 + 自定义参数
HyStatistical.track('subscribe_results', {
  'source': 'home_banner',
  'is_success': true,
  'product_id': 'year_dy',
  'period': 'yearly',   // weekly / monthly / yearly
});

// 无参数事件
HyStatistical.track('button_click');
```

事件名和 properties 完全由业务决定，服务端根据 `event_name` 和 JSON 自动识别展示。

## 配置项

```dart
HyStatisticalConfig(
  apiKey: 'required',                                  // 必填
  serverUrl: 'http://192.168.9.85:3000/api/v1',       // 默认后端地址
  flushInterval: 10,                                   // 秒，定时 flush
  flushSize: 50,                                       // 积累多少条立刻 flush
  maxRetries: 3,                                       // 网络错误重试次数
  enableLog: false,                                    // 打开后打印 [HyStatistical] 前缀的调试日志
);
```

## API 速查

| API | 说明 |
|---|---|
| `HyStatistical.initialize(config:, appVersion:, userId:)` | 初始化（idempotent，重复调用会忽略） |
| `HyStatistical.track(name, [properties])` | 上报事件 |
| `HyStatistical.setUserId(id)` | 用户登录/登出时更新 user_id |
| `HyStatistical.setAppVersion(version)` | 运行时更新 app_version |
| `HyStatistical.flush()` | 手动立刻 flush |
| `HyStatistical.clearPending()` | 清空内存队列 + 离线缓存（慎用） |
| `HyStatistical.deviceId` | 获取 SDK 生成的 device_id |
| `HyStatistical.pendingCount` | 队列里待发事件数 |
| `HyStatistical.dispose()` | 释放资源（退出前自动保存离线） |

## 自动采集

| 事件 | 触发时机 |
|------|---------|
| `app_open` | 首次初始化 |
| `app_foreground` | App 从后台回到前台 |

## 离线缓存和重试策略

- 事件先写入内存队列，按 `flushInterval` 或队列达到 `flushSize` 触发 flush
- HTTP 200 → 从队列移除
- HTTP 4xx → **该批直接丢弃**（业务参数有问题，重试无意义）
- HTTP 5xx / 网络错误 → 重试 `maxRetries` 次，最终失败写入 Keychain，下次启动自动恢复
- `insert_id` 是每条事件的 UUID，服务端根据这个去重

## 调试

开发期把 `enableLog: true` 打开，会看到：

```
[HyStatistical] init serverUrl=... apiKey=hy_xxx*** deviceId=... appVersion=1.0.0
[HyStatistical] lifecycle app_open
[HyStatistical] track name=xxx queue=1
[HyStatistical] flush → POST .../collect batch=1
[HyStatistical] flush OK {"accepted":1,"duplicates":0,"errors":0}
[HyStatistical] flush DROP status=400 body=...       ← 客户端错误，丢弃这批
[HyStatistical] flush FAIL attempt=1/3 status=500    ← 服务端错误，重试
[HyStatistical] saved N events offline                ← 重试用尽，写入离线
[HyStatistical] restored N events from offline cache
```

## 版本

查看 [Releases](https://github.com/1251627/hy-statistical-flutter/releases)。最新稳定版：`v0.1.4`。
