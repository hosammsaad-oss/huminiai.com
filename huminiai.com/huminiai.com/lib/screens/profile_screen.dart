import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart'; // لتشغيل المتصفح داخل التطبيق
import 'package:shared_preferences/shared_preferences.dart'; // لجلب البيانات المخزنة
import 'package:humini_ai/screens/new_purchase_screen.dart';
import 'social_leagues_screen.dart'; 
import '../RewardsStore/rewards_store.dart'; 
import 'settings_screen.dart'; // استيراد صفحة الإعدادات الجديدة
import 'accounts_agent_screen.dart';
import '../providers/life_provider.dart';







class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  File? _imageFile;

  // دالة وكيل الشراء الذكي
  void _startAutomatedPurchase(BuildContext context, String url, String siteName) async {
    // جلب البيانات من الذاكرة الحقيقية
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('user_name') ?? "مستخدم تجريبي";
    String phone = prefs.getString('user_phone') ?? "0500000000";
    String address = prefs.getString('user_address') ?? "العنوان الافتراضي";

    // تهيئة الـ Controller
    final WebViewController controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          // حقن كود التعبئة التلقائية بعد تحميل الصفحة
          controller.runJavaScript('''
            (function() {
              setTimeout(function() {
                const inputs = document.querySelectorAll('input, textarea');
                inputs.forEach(input => {
                  const id = (input.id || "").toLowerCase();
                  const nameAttr = (input.name || "").toLowerCase();
                  
                  if (id.includes('name') || nameAttr.includes('name')) input.value = "$name";
                  if (id.includes('phone') || nameAttr.includes('phone')) input.value = "$phone";
                  if (id.includes('address') || nameAttr.includes('address')) input.value = "$address";
                });
              }, 2500);
            })();
          ''');
        },
      ),
    );
    
    controller.loadRequest(Uri.parse(url));
    _showWebviewModal(context, controller, siteName);
  }

  // دالة إظهار نافذة المتصفح المنبثقة
  void _showWebviewModal(BuildContext context, WebViewController controller, String siteName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Text("وكيل الشراء الذكي: $siteName", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(child: WebViewWidget(controller: controller)),
          ],
        ),
      ),
    );
  }

  // دالة لحساب المستوى بناءً على النقاط
  int _calculateLevel(int points) {
    if (points <= 0) return 1;
    return (points / 500).floor() + 1;
  }

  // دالة لحساب التقدم داخل المستوى الحالي
  double _calculateLevelProgress(int points) {
    int currentLevelPoints = points % 500;
    return currentLevelPoints / 500;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم اختيار الصورة بنجاح")));
    }
  }

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


  // جلب قائمة المهام من الـ Provider
  final tasks = ref.watch(lifeProvider);
  // حساب المهام المنجزة والمتبقية
  final totalCompletedTasks = tasks.where((t) => t.isCompleted).length;
  final totalPendingTasks = tasks.length - totalCompletedTasks;



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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            int points = 0;
            String mood = "غير محدد";
            int energy = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              points = data['points'] ?? 0;
              mood = data['currentMood'] ?? "طبيعي";
              energy = data['energyLevel'] ?? 0;
            }

            int currentLevel = _calculateLevel(points);
            double levelProgress = _calculateLevelProgress(points);

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: levelProgress,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                          ),
                        ),
                        Stack(
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
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4EFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("مستوى $currentLevel", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(user?.displayName ?? "مستخدم هيومني", style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(user?.email ?? "humini.user@ai.com", style: GoogleFonts.poppins(color: Colors.grey)),

                  const SizedBox(height: 25),
                  // استدعاء ويدجت الإحصائيات التي أضفناها في الخطوة السابقة
                  _buildTaskStatsRow(totalCompletedTasks, totalPendingTasks),
                  const SizedBox(height: 20),

                  
                  const SizedBox(height: 25),
                  _buildBadgesSection(points, isDark),
                  const SizedBox(height: 20),
                  _buildPointsCard(points),
                  const SizedBox(height: 15),
                  _buildEmotionalQuickView(mood, energy, isDark),
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [



                        _buildProfileOption(
  context: context,
  icon: Icons.auto_awesome,
  title: "وكيل الشراء الذكي",
  color: const Color.fromARGB(255, 0, 0, 0),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPurchaseScreen()),
    );
  },
),







                 _buildProfileOption(
  context: context,
  icon: Icons.account_balance_wallet_rounded,
  title: "وكيل الحسابات الذكي",
  color: const Color.fromARGB(255, 0, 0, 0), // لون مختلف للتميز
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountsAgentScreen()),
    );
  },
),       










                        _buildProfileOption(
                          context: context, 
                          icon: Icons.leaderboard_outlined, 
                          title: "ساحة المنافسة", 
                          trailing: "تحديات الفريق",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialLeaguesScreen()));
                          }
                        ),
                        _buildProfileOption(
                          context: context, 
                          icon: Icons.shopping_bag_outlined, 
                          title: "متجر المكافآت", 
                          trailing: "استبدل نقاطك",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RewardsStore(currentPoints: points)));
                          }
                        ),
                        _buildProfileOption(
                          context: context, 
                          icon: Icons.settings_outlined, 
                          title: "إعدادات الوكيل", 
                          trailing: "خصوصية وسكون",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }



Widget _buildTaskStatsRow(int completed, int pending) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(vertical: 15),
    decoration: BoxDecoration(
      color: const Color(0xFF6B4EFF).withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("المنجزة", completed.toString(), Colors.green),
        Container(width: 1, height: 30, color: Colors.grey[300]),
        _buildStatItem("قيد العمل", pending.toString(), Colors.orange),
        Container(width: 1, height: 30, color: Colors.grey[300]),
        _buildStatItem("النجاح", "${(completed + pending == 0) ? 0 : (completed / (completed + pending) * 100).toInt()}%", Colors.blue),
      ],
    ),
  );
}

Widget _buildStatItem(String label, String value, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}








  // --- دوال الويدجت الفرعية المساعدة ---
  Widget _buildBadgesSection(int points, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text("خزانة الأوسمة 🎖️", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _badgeIcon("البداية", Icons.rocket_launch, points >= 50),
              _badgeIcon("المنضبط", Icons.verified, points >= 500),
              _badgeIcon("الخبير", Icons.psychology_alt, points >= 2000),
              _badgeIcon("الأسطورة", Icons.workspace_premium, points >= 5000),
              _badgeIcon("المنافس", Icons.military_tech, points >= 1000),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badgeIcon(String name, IconData icon, bool isUnlocked) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isUnlocked ? const Color(0xFF6B4EFF).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            child: Icon(icon, color: isUnlocked ? const Color(0xFF6B4EFF) : Colors.grey, size: 30),
          ),
          const SizedBox(height: 5),
          Text(name, style: GoogleFonts.tajawal(fontSize: 10, color: isUnlocked ? null : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("رصيد اليونيكورن", style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("$points نقطة", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.stars, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildEmotionalQuickView(String mood, int energy, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF6B4EFF), size: 20),
              const SizedBox(width: 8),
              Text("ملخص الحالة الذكي 🧠", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("المزاج الحالي:", style: GoogleFonts.tajawal(fontSize: 13)),
              Text(mood, style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("مستوى الحيوية:", style: GoogleFonts.tajawal(fontSize: 13)),
              Text("$energy%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: energy < 50 ? Colors.orange : Colors.green)),
            ],
          ),
        ],
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