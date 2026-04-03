import 'package:flutter/widgets.dart';

class HyLifecycleObserver with WidgetsBindingObserver {
  final void Function(String eventName) onLifecycleEvent;
  bool _hasLaunched = false;

  HyLifecycleObserver({required this.onLifecycleEvent});

  void start() {
    WidgetsBinding.instance.addObserver(this);
    if (!_hasLaunched) {
      _hasLaunched = true;
      onLifecycleEvent('app_open');
    }
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onLifecycleEvent('app_foreground');
    }
  }
}
