import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/services/reminder_scheduler_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    AuthService? authService,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _authService = authService ?? AuthService(),
        localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin() {
    scheduler = ReminderSchedulerService(plugin: localNotifications);
  }

  final FirebaseMessaging _messaging;
  final AuthService _authService;
  final FlutterLocalNotificationsPlugin localNotifications;
  late final ReminderSchedulerService scheduler;
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final android = localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);

      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final token = await _messaging.getToken();
      final uid = _authService.currentUser?.uid;
      if (token != null && uid != null) {
        await _authService.updateFcmToken(uid, token);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          await _authService.updateFcmToken(userId, newToken);
        }
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      await scheduler.ensureReady();
    } catch (e) {
      debugPrint('Notification init (non-fatal): $e');
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'MedReminder',
        body: notification.body ?? '',
      );
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'med_reminder_channel',
        'Medicine Reminders',
        channelDescription: 'Medicine reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await localNotifications.show(id, title, body, details);
  }

  Future<void> speakReminder(String patientName, String medicineName) async {
    await _tts.speak('$patientName, it\'s time to take your $medicineName.');
  }
}
