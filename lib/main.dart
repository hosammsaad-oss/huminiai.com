import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:humini_ai/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // سنبقي على تهيئة فايربيز لأن الذكاء الاصطناعي قد يحتاجها
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: HuminiApp()));
}

class HuminiApp extends StatelessWidget {
  const HuminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Humini AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      // الدخول مباشرة لصفحة الهوم بدون فحص تسجيل الدخول
      home: const HomeScreen(), 
    );
  }
}