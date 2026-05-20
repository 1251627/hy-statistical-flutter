# HyStatistical Flutter SDK

轻量级数据埋点 SDK：事件上报、批量发送、离线缓存、自动采集 App 生命周期事件、**广告归因（v0.3.0+，iOS）**。

## 安装

```yaml
# pubspec.yaml
dependencies:
  hy_statistical_flutter:
    git:
      url: https://github.com/1251627/hy-statistical-flutter.git
      ref: v0.3.0
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
      serverUrl: 'https://your-collect-domain.com/api/v1', // 必填
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
  serverUrl: '',                                       // 必填，例如 https://collect.your-domain.com/api/v1
  flushInterval: 10,                                   // 秒，定时 flush
  flushSize: 50,                                       // 积累多少条立刻 flush
  maxRetries: 3,                                       // 网络错误重试次数
  enableLog: false,                                    // 打开后打印 [HyStatistical] 前缀的调试日志
  enableAdAttribution: false,                          // v0.3.0+：开启后 SDK 在 App 内读取 IDFA / IDFV / PAID（仅 iOS）并随事件流上报到 serverUrl
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

## 广告归因（v0.3.0+，可选，仅 iOS）

如果需要把 App 用户与外部广告点击（如小红书聚光 / 巨量引擎）做归因匹配，开启 `enableAdAttribution`：

```dart
HyStatistical.initialize(
  config: HyStatisticalConfig(
    apiKey: 'your_api_key',
    serverUrl: 'https://collect.your-domain.com/api/v1',
    enableAdAttribution: true,    // 新参数，默认 false
  ),
  appVersion: info.version,
  userId: userId,
);
```

### 工作机制

- 数据走向：SDK 在你的 App 进程内读取设备字段 → 通过 platform channel 调原生 iOS → 随事件流 POST 到你自己配置的 `serverUrl/collect`。**SDK 作者不接触任何用户数据**，所有数据归你的服务端所有。
- **冷启动后**与 **`setUserId(_)`** 调用时，SDK 各触发一次设备指纹上报；同 visitorId 24 小时内最多上报一次。
- 读取字段：
  - **IDFA**：通过 `ASIdentifierManager`，**不弹 ATT 授权框**。用户未授权时系统返回全零 UUID，SDK 识别后上报空串
  - **IDFV**：通过 `UIDevice.identifierForVendor`，**无需用户授权**。同一开发者所有 App 间稳定。巨量引擎实时归因 API 必需
  - **PAID**：基于 App 安装时间 + 系统更新时间 + 设备启动时间的不可逆 MD5 三元组，无授权要求
- 算法与 iOS native SDK (hy_statistical_ios v0.4.0) **完全一致**——`HyAdFingerprint.swift` 是从 native SDK 直接 mirror 过来的，保证同设备同时刻算出的 IDFA / IDFV / PAID 字节相同
- 关闭归因（默认状态）时，SDK 行为与 v0.2.x 完全一致，**不读取任何广告标识符**
- Android 平台 v0.3.0 **不采集**（OAID 依赖业务方接入额外 SDK），事件上报照常工作

### App Store 审核

即使不弹 ATT，**`Info.plist` 中建议添加 `NSUserTrackingUsageDescription`** 描述用途（例如「用于评估广告投放效果」），否则部分审核员会拒绝。

### 隐私政策

启用归因前你的 App 隐私政策需明确声明读取 IDFA / IDFV / PAID 以及上报到你自己后端做归因。参考 `hy_statistical_ios` 仓库的 `PRIVACY_NOTICE_TEMPLATE.md`。

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

查看 [Releases](https://github.com/1251627/hy-statistical-flutter/releases)。最新稳定版：`v0.3.0`。

### v0.3.0 升级须知（向后兼容）

新增可选参数 `enableAdAttribution`（默认 `false`）。不开启的项目无需任何代码改动，从 v0.2.x 升级直接拉新版即可。

SDK 内部结构升级为 **Flutter plugin**（含原生 iOS 模块）。从 v0.2.x 升级到 v0.3.0 后，业务方 iOS 项目第一次 `flutter pub get` 之后需要 **`cd ios && pod install`**（标准 Flutter plugin 流程），否则 build iOS 时会提示找不到原生类。Android 端无需额外操作。

开启 `enableAdAttribution=true` 后 SDK 在你的 App 内读取 IDFA / IDFV / PAID 并上报到你自己的 `serverUrl`，详见上文「广告归因」章节。**启用前需在 App 隐私政策中声明**。

### v0.2.0 升级须知（破坏性变更）

`serverUrl` 从默认值改为**必填**。从 v0.1.x 升级时，`HyStatisticalConfig(apiKey: 'xxx')` 会编译失败。需要补上：

```dart
HyStatisticalConfig(
  apiKey: 'xxx',
  serverUrl: 'https://collect.your-domain.com/api/v1', // 新增此行
)
```

这一改动是为了避免「忘记改默认值，把生产事件错发到开发后端」的事故。
