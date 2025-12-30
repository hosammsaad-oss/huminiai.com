import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // تعريف الكائن بشكل مستقل لضمان التعرف على الـ Constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. بدء عملية تسجيل الدخول
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // المستخدم أغلق نافذة تسجيل الدخول
        setState(() => _isLoading = false);
        return;
      }

      // 2. جلب بيانات المصادقة (Tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. إنشاء كcredential للفايربيز
      // ملاحظة: استخدام 'as dynamic' في بعض الحالات يحل تضارب الأنواع في الويب
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول في فايربيز
      await FirebaseAuth.instance.signInWithCredential(credential);
      
    } catch (e) {
      debugPrint("خطأ في تسجيل الدخول: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل الدخول: تأكد من إعدادات الويب والـ SHA-1"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade600],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.auto_awesome, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Humini AI",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 35, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), 
                  topRight: Radius.circular(50)
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              child: Column(
                children: [
                  const Text(
                    "مرحباً بك", 
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "سجل دخولك لربط بياناتك واستخدام الذكاء الاصطناعي",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_Color_Logo.svg/1200px-Google_Color_Logo.svg.png',
                        height: 24,
                      ),
                      label: const Text(
                        "متابعة باستخدام جوجل",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        side: const BorderSide(color: Colors.black12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}