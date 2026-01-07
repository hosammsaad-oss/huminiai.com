import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// ضروري لربط المتجر
import 'social_leagues_screen.dart'; 
import '../RewardsStore/rewards_store.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  File? _imageFile;

  // 1. دالة تغيير الصورة
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم اختيار الصورة بنجاح")));
    }
  }

  // 2. دالة تعديل الاسم
  void _showEditNameDialog() {
    final controller = TextEditingController(text: user?.displayName);
    _showStyledDialog(
      title: "تعديل الاسم",
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: "الاسم الجديد")),
      onConfirm: () async {
        await user?.updateDisplayName(controller.text);
        setState(() {});
      },
    );
  }

  // 3. دالة تغيير البريد الإلكتروني
  void _showEditEmailDialog() {
    final controller = TextEditingController(text: user?.email);
    _showStyledDialog(
      title: "تغيير البريد الإلكتروني",
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: "البريد الجديد")),
      onConfirm: () async {
        try {
          await user?.verifyBeforeUpdateEmail(controller.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم إرسال رابط تأكيد إلى البريد الجديد")),
            );
          }
        } catch (e) {
          _showErrorSnackBar(e.toString());
        }
      },
    );
  }

  // 4. دالة إعادة تعيين كلمة المرور
  void _resetPassword() async {
    if (user?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك")),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  // 5. دالة اختيار اللغة
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("اختر اللغة", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(title: const Text("العربية"), trailing: const Icon(Icons.check, color: Color(0xFF6B4EFF)), onTap: () => Navigator.pop(context)),
              ListTile(title: const Text("English"), onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showStyledDialog({required String title, required Widget content, required Function onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: content,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF)),
              onPressed: () async {
                await onConfirm();
                if (mounted) Navigator.pop(context);
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $message"), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("الملف الشخصي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                      child: (user?.photoURL == null && _imageFile == null)
                          ? Text(user?.email?.substring(0, 1).toUpperCase() ?? "H", style: GoogleFonts.poppins(fontSize: 50, fontWeight: FontWeight.bold, color: const Color(0xFF6B4EFF)))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF6B4EFF),
                        radius: 18,
                        child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _pickImage),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(user?.displayName ?? "مستخدم هيومني", style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(user?.email ?? "humini.user@ai.com", style: GoogleFonts.poppins(color: Colors.grey)),
              
              // عرض النقاط بشكل حي
              const SizedBox(height: 20),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  int points = 0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    points = data['points'] ?? 0;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          "$points نقطة",
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // زر الدخول لمتجر المكافآت
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        int points = 0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          points = (snapshot.data!.data() as Map<String, dynamic>)['points'] ?? 0;
                        }
                        return _buildProfileOption(
                          context: context, 
                          icon: Icons.shopping_bag_outlined, 
                          title: "متجر المكافآت", 
                          trailing: "استبدل نقاطك",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RewardsStore(currentPoints: points)),
                            );
                          }
                        );
                      }
                    ),
                    _buildProfileOption(context: context, icon: Icons.person_outline, title: "تعديل الاسم", onTap: _showEditNameDialog),
                    _buildProfileOption(context: context, icon: Icons.email_outlined, title: "تغيير البريد الإلكتروني", onTap: _showEditEmailDialog),
                    _buildProfileOption(context: context, icon: Icons.lock_outline, title: "تغيير كلمة المرور", onTap: _resetPassword),
                    _buildProfileOption(context: context, icon: Icons.language, title: "لغة التطبيق", trailing: "العربية", onTap: _showLanguagePicker),
                    const Divider(height: 40),
                    _buildProfileOption(
                      context: context,
                      icon: Icons.logout,
                      title: "تسجيل الخروج",
                      color: Colors.redAccent,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({required BuildContext context, required IconData icon, required String title, String? trailing, Color? color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white70 : Colors.black87;
    final finalColor = color ?? defaultTextColor;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: finalColor == Colors.redAccent ? Colors.red.withOpacity(0.1) : const Color(0xFF6B4EFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: finalColor == Colors.redAccent ? Colors.redAccent : const Color(0xFF6B4EFF)),
      ),
      title: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: finalColor)),
      trailing: trailing != null ? Text(trailing, style: GoogleFonts.tajawal(color: Colors.grey)) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}

