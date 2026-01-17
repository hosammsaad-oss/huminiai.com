import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // مكتبة التخزين
import '../providers/chat_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  // --- [تم الإضافة] دالة تحديث مواعيد السكون التي يطلبها الـ UI ---
  static Future<void> updateSleepSettings(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleep_start_hour', startHour);
    await prefs.setInt('sleep_end_hour', endHour);
    print("✅ تم حفظ توقيت السكون الجديد: من $startHour إلى $endHour");
  }

  // --- تشغيل وكيل الذكاء الاصطناعي مع التحقق من وقت السكون ---
  static Future<void> startAIReceiver(WidgetRef ref) async {
    bool hasPermission = await NotificationsListener.hasPermission ?? false;
    if (!hasPermission) {
      await NotificationsListener.openPermissionSettings();
      return;
    }

    await NotificationsListener.initialize(callbackHandle: _onNotificationBackgroundAction);
    
    // الحصول على المواعيد المخزنة
    final prefs = await SharedPreferences.getInstance();
    int sleepStart = prefs.getInt('sleep_start_hour') ?? 23; 
    int sleepEnd = prefs.getInt('sleep_end_hour') ?? 7;      

    NotificationsListener.receivePort?.listen((dynamic evt) {
      if (evt is NotificationEvent) {
        final now = DateTime.now();
        bool isInSleepMode = false;

        // منطق التحقق من فترة السكون (يدعم عبور منتصف الليل)
        if (sleepStart > sleepEnd) {
          if (now.hour >= sleepStart || now.hour < sleepEnd) isInSleepMode = true;
        } else {
          if (now.hour >= sleepStart && now.hour < sleepEnd) isInSleepMode = true;
        }

        if (isInSleepMode) {
          print("💤 هوميني في وضع السكون الآن.. يتجاهل الإشعار.");
          return; 
        }

        _analyzeWithHumini(evt, ref);
      }
    });
  }

  static void _analyzeWithHumini(NotificationEvent evt, WidgetRef ref) {
    final appsToMonitor = ["com.whatsapp", "com.google.android.calendar", "com.android.settings"];
    if (appsToMonitor.contains(evt.packageName)) {
      String title = evt.title ?? "إشعار جديد";
      String content = evt.text ?? "";
      String contextData = "تطبيق: ${evt.packageName}, العنوان: $title, النص: $content";
      ref.read(chatProvider.notifier).analyzeExternalNotification(contextData);
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationBackgroundAction(dynamic evt) {
    if (evt is NotificationEvent) {
      print("Humini Background: ${evt.packageName}");
    }
  }

  // الوظائف الأصلية
  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails('humini_channel', 'Humini Notifications', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(0, title, body, details);
  }

  static Future<void> scheduleDailyTip() async {
    await _notificationsPlugin.zonedSchedule(
      1, 'نصيحة هوميني اليومية 💡', 'هل تعلم أن الذكاء الاصطناعي يمكنه مساعدتك؟',
      _nextInstanceOfTenAM(),
      const NotificationDetails(android: AndroidNotificationDetails('daily_tip', 'Daily Tips')),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }
  // --- [إضافة جديدة] دالة لجدولة تذكير بمهام اليوم المتبقية ---
  static Future<void> scheduleTaskReminder(int remainingTasks) async {
    if (remainingTasks == 0) return; // لا ترسل تنبيهاً إذا انتهت كل المهام

    await _notificationsPlugin.zonedSchedule(
      100, // ID مميز لتنبيه المهام
      'بقي القليل على الإنجاز! 🎯',
      'لديك $remainingTasks مهام متبقية لليوم. هوميني يشجعك على إنهائها الآن.',
      _nextInstanceOfTime(18, 0), // جدولتها للساعة 6 مساءً مثلاً
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders', 'تذكيرات المهام',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // دالة مساعدة لتحديد الوقت بدقة
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}