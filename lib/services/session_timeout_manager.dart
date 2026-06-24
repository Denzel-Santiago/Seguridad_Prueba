import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimeoutManager extends ChangeNotifier {
  static final SessionTimeoutManager _instance = SessionTimeoutManager._internal();
  factory SessionTimeoutManager() => _instance;
  SessionTimeoutManager._internal();

  final Duration inactivityLimit = const Duration(seconds: 15);
  DateTime? _lastActivity;
  Timer? _expirationTimer;
  Timer? _uiTicker;
  bool _isSessionActive = false;
  VoidCallback? _onTimeout;

  bool get isSessionActive => _isSessionActive;

  Duration get remainingTime {
    if (!_isSessionActive || _lastActivity == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = inactivityLimit - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get remainingSeconds => remainingTime.inSeconds;

  double get inactivityProgress {
    if (!_isSessionActive || _lastActivity == null) {
      return 1.0;
    }

    final elapsed = DateTime.now().difference(_lastActivity!);
    final progress =
        1.0 - (elapsed.inMilliseconds / inactivityLimit.inMilliseconds);

    return progress.clamp(0.0, 1.0);
  }

  Duration get elapsedInactivity {
    if (_lastActivity == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastActivity!);
    return elapsed > inactivityLimit ? inactivityLimit : elapsed;
  }

  void setOnTimeoutListener(VoidCallback onTimeout) {
    _onTimeout = onTimeout;
  }

  void startSession() {
    _isSessionActive = true;
    _lastActivity = DateTime.now();
    _startExpirationTimer();
    _startUiTicker();
    notifyListeners();
  }

  void stopSession() {
    _isSessionActive = false;
    _expirationTimer?.cancel();
    _uiTicker?.cancel();
    _expirationTimer = null;
    _uiTicker = null;
    notifyListeners();
  }

  void registerActivity() {
    if (!_isSessionActive) return;
    _lastActivity = DateTime.now();
    _startExpirationTimer();
    notifyListeners();
  }

  void _startExpirationTimer() {
    _expirationTimer?.cancel();
    final remaining = remainingTime;
    if (remaining <= Duration.zero) {
      _handleTimeout();
      return;
    }
    _expirationTimer = Timer(remaining, _handleTimeout);
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (_isSessionActive) {
          notifyListeners();
        } else {
          _uiTicker?.cancel();
          _uiTicker = null;
        }
      },
    );
  }

  void _handleTimeout() {
    if (!_isSessionActive) return;
    stopSession();
    _onTimeout?.call();
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (!_isSessionActive) return;

    if (state == AppLifecycleState.resumed) {
      final elapsedSinceLastActivity = DateTime.now().difference(_lastActivity!);
      if (elapsedSinceLastActivity >= inactivityLimit) {
        _handleTimeout();
      } else {
        _startExpirationTimer();
        _startUiTicker();
        notifyListeners();
      }
    } else if (state == AppLifecycleState.paused) {
      _expirationTimer?.cancel();
      _uiTicker?.cancel();
    }
  }
}
