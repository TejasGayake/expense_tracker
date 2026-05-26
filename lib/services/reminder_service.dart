import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  Future<void> sendReminder({
    required String personName,
    required double amount,
    String? notes,
  }) async {
    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Payment Reminders',
      channelDescription: 'Notifications for payment reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    // Platform-specific details
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show notification
    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      'Payment Reminder',
      '${personName} owes you ₹${amount.toStringAsFixed(2)}${notes != null ? '\n$notes' : ''}',
      platformDetails,
    );
  }

  Future<void> scheduleReminder({
    required String personName,
    required double amount,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Payment Reminders',
      channelDescription: 'Notifications for payment reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    // Platform-specific details
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule notification
    await _notifications.zonedSchedule(
      DateTime.now().millisecond,
      'Payment Reminder',
      '${personName} owes you ₹${amount.toStringAsFixed(2)}${notes != null ? '\n$notes' : ''}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}