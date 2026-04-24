import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HyEventQueue {
  final String serverUrl;
  final String apiKey;
  final int flushSize;
  final int flushInterval;
  final int maxRetries;
  final bool enableLog;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _flushing = false;

  static const _storageKey = 'hy_statistical_offline_events';
  final _storage = const FlutterSecureStorage();

  HyEventQueue({
    required this.serverUrl,
    required this.apiKey,
    this.flushSize = 50,
    this.flushInterval = 10,
    this.maxRetries = 3,
    this.enableLog = false,
  });

  Future<void> start() async {
    await _restoreOfflineEvents();
    _timer = Timer.periodic(Duration(seconds: flushInterval), (_) => flush());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void add(Map<String, dynamic> event) {
    _queue.add(event);
    if (_queue.length >= flushSize) {
      flush();
    }
  }

  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;

    final batch = List<Map<String, dynamic>>.from(
      _queue.take(flushSize > _queue.length ? _queue.length : flushSize),
    );

    _log('flush → POST $serverUrl/collect batch=${batch.length}');

    var success = false;
    dynamic lastError;
    int lastStatus = 0;
    String lastBody = '';
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$serverUrl/collect'),
          headers: {
            'Content-Type': 'application/json',
            'X-Api-Key': apiKey,
          },
          body: jsonEncode({'events': batch}),
        );
        lastStatus = response.statusCode;
        lastBody = response.body;
        if (response.statusCode == 200) {
          success = true;
          _log('flush OK ${response.body}');
          break;
        }
        _log('flush FAIL attempt=${attempt + 1}/$maxRetries status=$lastStatus body=$lastBody');
      } catch (e) {
        lastError = e;
        _log('flush FAIL attempt=${attempt + 1}/$maxRetries error=$e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    if (success) {
      _queue.removeRange(0, batch.length);
      await _storage.delete(key: _storageKey);
    } else {
      _log('flush GIVE UP after $maxRetries attempts lastStatus=$lastStatus lastError=$lastError; saving ${_queue.length} events offline');
      await _saveOfflineEvents();
    }

    _flushing = false;
  }

  Future<void> _saveOfflineEvents() async {
    if (_queue.isEmpty) return;
    final json = jsonEncode(_queue);
    await _storage.write(key: _storageKey, value: json);
    _log('saved ${_queue.length} events offline');
  }

  Future<void> _restoreOfflineEvents() async {
    final json = await _storage.read(key: _storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        final list = jsonDecode(json) as List;
        for (final item in list) {
          _queue.add(Map<String, dynamic>.from(item));
        }
        _log('restored ${list.length} events from offline cache');
      } catch (_) {
        await _storage.delete(key: _storageKey);
      }
    }
  }

  int get pendingCount => _queue.length;

  void _log(String msg) {
    if (enableLog) debugPrint('[HyStatistical] $msg');
  }
}
