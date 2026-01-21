// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 1. دالة الدخول كضيف
  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // سيتم التحويل للهوم تلقائياً بفضل الـ StreamBuilder في main.dart
    } catch (e) {
      _showError("فشل الدخول كضيف: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. دالة جوجل
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } catch (e) {
      _showError("فشل تسجيل الدخول بجوجل: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. دالة البريد الإلكتروني
  Future<void> _processAuth(bool isRegistration) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError("يرجى ملء كافة الحقول");
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (isRegistration) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "حدث خطأ ما");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 10),
              const Text("HUMINI AI", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "البريد الإلكتروني",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "كلمة المرور",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const CircularProgressIndicator(color: Colors.deepPurpleAccent)
              else ...[
                // زر الدخول بالبريد
                ElevatedButton(
                  onPressed: () => _processAuth(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("تسجيل الدخول", style: TextStyle(color: Colors.white)),
                ),
                
                const SizedBox(height: 15),
                
                // زر جوجل
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 20),
                  label: const Text("الدخول بواسطة جوجل", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),

                const SizedBox(height: 10),

                // زر الدخول كضيف (جديد)
                TextButton(
                  onPressed: _signInAnonymously,
                  child: const Text("استخدام كضيف (بدون حساب)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                
                const Divider(),
                
                TextButton(
                  onPressed: () => _processAuth(true),
                  child: const Text("ليس لديك حساب؟ إنشاء حساب بريد", style: TextStyle(color: Colors.deepPurpleAccent)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}