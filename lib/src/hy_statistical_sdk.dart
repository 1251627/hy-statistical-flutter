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
  late final HyLifecycleObserver _lifecycle;

  String? _userId;
  String _sessionId = '';
  String _appVersion = '';
  String _deviceId = '';

  HyStatistical._({
    required HyDeviceInfo deviceInfo,
    required HyEventQueue queue,
  })  : _deviceInfo = deviceInfo,
        _queue = queue;

  static Future<void> initialize({
    required HyStatisticalConfig config,
    String? appVersion,
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
    );

    final instance = HyStatistical._(
      deviceInfo: deviceInfo,
      queue: queue,
    );

    instance._deviceId = deviceId;
    instance._appVersion = appVersion ?? '';
    instance._sessionId = _uuid.v4().substring(0, 8);

    instance._lifecycle = HyLifecycleObserver(
      onLifecycleEvent: (eventName) {
        if (eventName == 'app_foreground' || eventName == 'app_open') {
          instance._sessionId = _uuid.v4().substring(0, 8);
        }
        instance._trackInternal(eventName);
      },
    );

    _instance = instance;

    await queue.start();
    instance._lifecycle.start();
  }

  static void track(String eventName, [Map<String, dynamic>? properties]) {
    _instance?._trackInternal(eventName, properties);
  }

  static void setUserId(String? userId) {
    _instance?._userId = userId;
  }

  static void setAppVersion(String version) {
    _instance?._appVersion = version;
  }

  static Future<void> flush() async {
    await _instance?._queue.flush();
  }

  static String? get deviceId => _instance?._deviceId;

  static int get pendingCount => _instance?._queue.pendingCount ?? 0;

  static void dispose() {
    _instance?._lifecycle.stop();
    _instance?._queue.stop();
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
      'app_version': _appVersion,
      'os_version': _deviceInfo.osVersion,
    };
    if (_userId != null && _userId!.isNotEmpty) {
      event['user_id'] = _userId;
    }
    if (properties != null && properties.isNotEmpty) {
      event['properties'] = properties;
    }
    _queue.add(event);
  }
}
