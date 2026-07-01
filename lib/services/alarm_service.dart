import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  final AudioPlayer _player = AudioPlayer();
  bool _ringing = false;

  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _notifInit = false;

  // ── Init notifications (call once at app start) ───────────────────────────
  static Future<void> initNotifications() async {
    if (_notifInit) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _notifInit = true;
  }

  // ── Sound + vibration alarm ───────────────────────────────────────────────
  Future<void> trigger({String soundName = 'alarm_default'}) async {
    if (_ringing) return;
    _ringing = true;

    // Vibrate pattern: long-short-long
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 800]);
    }

    try {
      await _player.play(AssetSource('audio/$soundName.mp3'));
    } catch (e) {
      debugPrint('[AlarmService] Audio play error: $e');
    }

    // Push notification (visible even when app is backgrounded)
    await _sendNotification();
  }

  Future<void> stop() async {
    if (!_ringing) return;
    _ringing = false;
    await _player.stop();
    Vibration.cancel();
  }

  static Future<void> _sendNotification() async {
    const android = AndroidNotificationDetails(
      'tank_alert',
      'Tank Alerts',
      channelDescription: 'Jal Rakshak tank fill notifications',
      importance: Importance.max,
      priority:   Priority.high,
      ticker:     'Tank filled',
      playSound:  false, // We play our own
    );
    await _notifications.show(
      1,
      '💧 Tank Filled!',
      'Your water tank has been filled. Turn off the motor.',
      const NotificationDetails(android: android),
    );
  }

  void dispose() {
    _player.dispose();
  }
}
