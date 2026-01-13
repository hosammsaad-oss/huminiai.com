import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; // مكتبة الموقع
import 'package:firebase_messaging/firebase_messaging.dart'; // للإشعارات
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // للتنبيهات المحلية
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:flutter/foundation.dart';

// استيراد الملفات الخاصة بمشروعك
import 'screens/home_screen.dart';
import 'firebase_options.dart'; 

// إعدادات الإشعارات العالمية
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// مزود حالة الثيم (Theme Provider)
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// دالة فحص وطلب إذن الموقع
Future<void> _checkLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }
  
  if (permission == LocationPermission.deniedForever) return;
}

void main() async {
  // 1. التأكد من تهيئة روابط الويدجت
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة الـ WebView للعمل على الويب (حل مشكلة وكيل الشراء)
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  // 3. طلب إذن الموقع عند بدء التشغيل
  await _checkLocationPermission();

  // 4. تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 5. تهيئة نظام الإشعارات الذكي
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'humini_main_channel', 
    'تنبيهات هوميني الذكية', 
    description: 'تستخدم لإشعارات المكافآت والترتيب العالمي', 
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 6. طلب إذن الإشعارات من المستخدم
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 7. تسجيل دخول مجهول لضمان استقرار الصلاحيات
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Auth Error: $e");
    }
  }

  // 8. تشغيل التطبيق
  runApp(
    const ProviderScope(
      child: HuminiApp(),
    ),
  );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          primary: const Color(0xFF6B4EFF),
          secondary: const Color(0xFF00D2FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFFBFBFE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          primary: const Color(0xFF8E78FF),
          secondary: const Color(0xFF00D2FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), 
        ),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "HUMINI",
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "ذكاء يتحدث لغتك",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}