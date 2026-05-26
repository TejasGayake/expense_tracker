import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  static void stopTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      if (kDebugMode) {
        print('⏱️ [PERF] $operation took: ${timer.elapsedMilliseconds}ms');
      }
      _timers.remove(operation);
    }
  }
  
  static void logFrameTime(String operation, Duration duration) {
    if (duration.inMilliseconds > 16) { // 60fps = ~16ms per frame
      if (kDebugMode) {
        print('⚠️ [PERF] $operation took ${duration.inMilliseconds}ms (exceeds 16ms)');
      }
    }
  }
  
  static Widget monitorWidget(String name, Widget child) {
    return Builder(
      builder: (context) {
        final stopwatch = Stopwatch()..start();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          logFrameTime('$name build', stopwatch.elapsed);
        });
        return child;
      },
    );
  }
}