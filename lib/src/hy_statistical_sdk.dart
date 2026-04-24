import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'hy_statistical_config.dart';
import 'hy_device_info.dart';
import 'hy_event_queue.dart';
import 'hy_lifecycle_observer.dart';

/// HyStatistical 数据埋点 Flutter SDK
///
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await HyStatistical.initialize(config: HyStatisticalConfig(apiKey: 'your_key'));
/// runApp(MyApp());
///
/// HyStatistical.track('subscribe_success', {'plan_id': 'pro_monthly'});
/// HyStatistical.setUserId('user_123');
/// ```
class HyStatistical {
  static HyStatistical? _instance;
  static const _uuid = Uuid();

  final HyDeviceInfo _deviceInfo;
  final HyEventQueue _queue;
  final bool _enableLog;
  late final HyLifecycleObserver _lifecycle;

  String? _userId;
  String _sessionId = '';
  String _appVersion = '';
  String _deviceId = '';

  HyStatistical._({
    required HyDeviceInfo deviceInfo,
    required HyEventQueue queue,
    required bool enableLog,
  })  : _deviceInfo = deviceInfo,
        _queue = queue,
        _enableLog = enableLog;

  static Future<void> initialize({
    required HyStatisticalConfig config,
    String? appVersion,
    String? userId,
  }) async {
    if (_instance != null) return;

    final deviceInfo = HyDeviceInfo();
    final deviceId = await deviceInfo.getDeviceId();

    final queue = HyEventQueue(
      serverUrl: config.serverUrl,
      apiKey: config.apiKey,
      flushSize: config.flushSize,
      flushInterval: config.flushInterval,
      maxRetries: config.maxRetries,
      enableLog: config.enableLog,
    );

    final instance = HyStatistical._(
      deviceInfo: deviceInfo,
      queue: queue,
      enableLog: config.enableLog,
    );

    instance._deviceId = deviceId;
    instance._appVersion = appVersion ?? '';
    // 在生命周期启动前设好 userId，保证首条 app_open 事件也带 user_id
    if (userId != null && userId.isNotEmpty) {
      instance._userId = userId;
    }
    instance._sessionId = _uuid.v4().substring(0, 8);

    instance._lifecycle = HyLifecycleObserver(
      onLifecycleEvent: (eventName) {
        if (eventName == 'app_foreground' || eventName == 'app_open') {
          instance._sessionId = _uuid.v4().substring(0, 8);
        }
        instance._log('lifecycle $eventName');
        instance._trackInternal(eventName);
      },
    );

    _instance = instance;

    if (config.enableLog) {
      final masked = config.apiKey.length > 8
          ? '${config.apiKey.substring(0, 8)}***'
          : '***';
      debugPrint('[HyStatistical] init serverUrl=${config.serverUrl} '
          'apiKey=$masked deviceId=$deviceId appVersion=${instance._appVersion} '
          'platform=${deviceInfo.platform} flushInterval=${config.flushInterval}s '
          'flushSize=${config.flushSize} maxRetries=${config.maxRetries} '
          'userId=${userId ?? '(null)'}');
    }

    await queue.start();
    instance._lifecycle.start();
  }

  static void track(String eventName, [Map<String, dynamic>? properties]) {
    _instance?._trackInternal(eventName, properties);
  }

  static void setUserId(String? userId) {
    _instance?._userId = userId;
    _instance?._log('setUserId ${userId ?? '(null)'}');
  }

  static void setAppVersion(String version) {
    _instance?._appVersion = version;
  }

  static Future<void> flush() async {
    await _instance?._queue.flush();
  }

  /// 清空内存队列和离线缓存中的所有待发事件。适合业务方在检测到
  /// 历史数据已不可用（例如格式版本升级、切换后端）时主动调用。
  static Future<void> clearPending() async {
    await _instance?._queue.clearPending();
  }

  static String? get deviceId => _instance?._deviceId;

  static int get pendingCount => _instance?._queue.pendingCount ?? 0;

  /// 停止 SDK 并把内存队列保存到离线缓存，避免事件丢失。
  /// 调用后需要重新 initialize 才能继续使用。
  static Future<void> dispose() async {
    final inst = _instance;
    if (inst == null) return;
    inst._lifecycle.stop();
    await inst._queue.stop();
    _instance = null;
  }

  void _trackInternal(String eventName, [Map<String, dynamic>? properties]) {
    final event = <String, dynamic>{
      'platform': _deviceInfo.platform,
      'event_name': eventName,
      'event_time': DateTime.now().toIso8601String(),
      'device_id': _deviceId,
      'session_id': 's_$_sessionId',
      'insert_id': _uuid.v4(),
      // 业务方若未传 appVersion 兜底为 'unknown'，避免被后端 @IsNotEmpty 拒绝
      'app_version': _appVersion.isNotEmpty ? _appVersion : 'unknown',
      'os_version': _deviceInfo.osVersion,
    };
    if (_userId != null && _userId!.isNotEmpty) {
      event['user_id'] = _userId;
    }
    if (properties != null && properties.isNotEmpty) {
      event['properties'] = properties;
    }
    _queue.add(event);
    _log('track name=$eventName queue=${_queue.pendingCount}'
        '${properties != null && properties.isNotEmpty ? ' props=$properties' : ''}');
  }

  void _log(String msg) {
    if (_enableLog) debugPrint('[HyStatistical] $msg');
  }
}
