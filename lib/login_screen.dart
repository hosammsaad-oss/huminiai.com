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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في تسجيل الدخول: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.auto_awesome, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Humini AI",
              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("مستقبلك مع الذكاء الاصطناعي يبدأ هنا", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 50),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "تسجيل الدخول",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        label: const Text("المتابعة باستخدام جوجل"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}