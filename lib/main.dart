import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // إضافة مكتبة env

// نستخدم التسمية tel لضمان عدم تداخل الأنواع
import 'package:telephony/telephony.dart' as tel;

import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/groq_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _showBackgroundNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'humini_main_channel',
        'تنبيهات هوميني الذكية',
        importance: Importance.max,
        priority: Priority.high,
      );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

// ------------------------------------------------------------------
// الحل النهائي: استخدام dynamic لتخطي فحص النوع الصارم
// ------------------------------------------------------------------
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // تحميل env داخل الخلفية أيضاً لضمان قراءة المفاتيح
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    if (taskName == "smsCheckTask") {
      try {
        final dynamic telephony = tel.Telephony.instance;

        final List<tel.SmsMessage> messages = await telephony.getInbox(
          columns: [
            tel.SmsColumn.ADDRESS,
            tel.SmsColumn.BODY,
            tel.SmsColumn.DATE,
          ],
          filter: tel.SmsFilter.where(tel.SmsColumn.DATE).greaterThan(
            DateTime.now()
                .subtract(const Duration(minutes: 15))
                .millisecondsSinceEpoch
                .toString(),
          ),
          sortOrder: [tel.OrderBy(tel.SmsColumn.DATE, sort: tel.Sort.DESC)],
        );

        if (messages.isNotEmpty) {
          String smsBody = messages.first.body ?? "";
          if (smsBody.contains("شراء") ||
              smsBody.contains("خصم") ||
              smsBody.contains("مدى")) {
            final groq = GroqService();
            String prompt =
                "استخرج المبلغ والمتجر من رسالة البنك: $smsBody. رد باختصار: المبلغ | المتجر";
            String aiResponse = await groq.getAIResponse(prompt);
            await _showBackgroundNotification(
              "رصد مالي ذكي 💸",
              "تحليل العملية: $aiResponse",
            );
          }
        }
      } catch (e) {
        debugPrint("Background SMS Error: $e");
      }
    } else if (taskName == "weeklySummaryTask") {
      try {
        final groq = GroqService();
        String aiAdvice = await groq.getAIResponse(
          "يا هلا يا حسام، نصيحة مالية قصيرة جداً.",
        );
        await _showBackgroundNotification("📊 ملخصك الأسبوعي", aiAdvice);
      } catch (e) {
        debugPrint("Weekly Report Error: $e");
      }
    }
    return Future.value(true);
  });
}

// ------------------------------------------------------------------
// كود تشغيل التطبيق (Firebase & UI)
// ------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> _checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تحميل مفاتيح الـ API قبل كل شيء
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv Load Error: $e");
  }

  // 2. تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. تهيئة Workmanager (فقط للأجهزة الحقيقية وليس الويب)
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
        "1",
        "smsCheckTask",
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      await Workmanager().registerPeriodicTask(
        "2",
        "weeklySummaryTask",
        frequency: const Duration(days: 7),
        initialDelay: const Duration(days: 1),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint("Workmanager Init Error: $e");
    }
  } else {
    // إعدادات الويب
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  await _checkLocationPermission();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'humini_main_channel',
    'تنبيهات هوميني الذكية',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Auth Error: $e");
    }
  }

  runApp(const ProviderScope(child: HuminiApp()));
}

class HuminiApp extends ConsumerWidget {
  const HuminiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'هوميني AI',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EFF)),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "HUMINI",
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "حسام سعد",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
