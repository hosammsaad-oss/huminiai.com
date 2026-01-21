import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// استدعاء الملفات الأصلية فقط لمنع التكرار
import '../providers/life_provider.dart'; 

class SmartDashboardScreen extends ConsumerStatefulWidget {
  const SmartDashboardScreen({super.key});

  @override
  ConsumerState<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends ConsumerState<SmartDashboardScreen> {
  bool _isPhoneVisible = false;
  File? _imageFile;
  final user = FirebaseAuth.instance.currentUser;

  String education = "جاري التحميل...";
  String jobTitle = "جاري التحميل...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        education = doc.data()?['education'] ?? "لم يحدد بعد";
        jobTitle = doc.data()?['jobTitle'] ?? "مستخدم هوميني";
      });
    }
  }

  // --- ميزة رفع الصورة الشخصية (Base64 لسهولة الاستخدام) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 15,
      maxWidth: 200,
      maxHeight: 200,
    );

    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
      await _uploadProfileImage();
    }
  }
double getCategoryValue(List<TaskModel> tasks, String hqiCat) {
  // حساب المهام المكتملة التي تنتمي لتصنيف معين
  int completed = tasks.where((t) => t.hqiCategory == hqiCat && t.isCompleted).length;
  // كل مهمة ترفع الرادار بنسبة 20% بحد أقصى 100%
  return (completed * 20.0).clamp(0.0, 100.0);
}
  Future<void> _uploadProfileImage() async {
    if (_imageFile == null || user == null) return;
    try {
      final bytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'photoURL': base64Image,
      }, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الصورة بنجاح! ✅")));
    } catch (e) {
      debugPrint("Error uploading: $e");
    }
  }

  // --- نظام مؤشر الجودة البشري (Radar Chart) ---
  Widget _buildHumanQualityIndex(List<TaskModel> tasks) {
    // حساب قيم الرادار بناءً على المهام الحقيقية (كمثال تفاعلي)
    double calc(String cat) => tasks.where((t) => t.isCompleted).length * 20.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("مؤشر الجودة البشري (HQI)", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("تصنيفك: أعلى 12% عالمياً", style: GoogleFonts.tajawal(fontSize: 12, color: Colors.green)),
                ],
              ),
              const Icon(Icons.analytics_outlined, color: Color(0xFF6B4EFF), size: 28),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF6B4EFF).withOpacity(0.2),
                    borderColor: const Color(0xFF6B4EFF),
                    entryRadius: 3,
                    dataEntries: [
                     RadarEntry(value: getCategoryValue(tasks, 'التزام')),
                     RadarEntry(value: getCategoryValue(tasks, 'سرعة')),
                     RadarEntry(value: getCategoryValue(tasks, 'تواصل')),
                     RadarEntry(value: getCategoryValue(tasks, 'تطور')),
                     RadarEntry(value: getCategoryValue(tasks, 'دقة')),
                    ],
                  ),
                ],
                getTitle: (index, angle) {
                  const titles = ['الالتزام', 'السرعة', 'التواصل', 'التطور', 'الدقة'];
                  return RadarChartTitle(text: titles[index], angle: angle);
                },
                radarShape: RadarShape.circle,
                tickCount: 5,
                gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // استدعاء البيانات من الـ Providers الأصلية المعرفة في ملفاتك الأخرى
    final userXPAsync = ref.watch(userXPProvider);
    final tasks = ref.watch(lifeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF0F2F8),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: userXPAsync.when(
          data: (xp) => CustomScrollView(
            slivers: [
              _buildModernHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildHumanQualityIndex(tasks), 
                      const SizedBox(height: 25),
                      _buildDailyQuests(tasks),
                      const SizedBox(height: 25),
                      _buildBadgesSection(xp),
                      const SizedBox(height: 25),
                      _buildSectionTitle("المعلومات المهنية"),
                      Row(
                        children: [
                          _buildStatCard("المؤهل", education, Icons.school, Colors.orange),
                          const SizedBox(width: 15),
                          _buildStatCard("اللقب", jobTitle, Icons.work, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildInfoSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("حدث خطأ: $e")),
        ),
      ),
    );
  }

  // --- مكوّنات الواجهة المساعدة لمنع تكرار الدوال في الملفات الأخرى ---

  Widget _buildModernHeader() {
    return SliverAppBar(
      expandedHeight: 200, pinned: true,
      backgroundColor: const Color(0xFF6B4EFF),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)])),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildProfileImageAvatar(),
              const SizedBox(height: 10),
              Text(user?.displayName ?? "مستخدم هوميني", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageAvatar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String? photo;
        if (snapshot.hasData && snapshot.data!.exists) photo = (snapshot.data!.data() as Map<String, dynamic>)['photoURL'];
        return CircleAvatar(
          radius: 40, backgroundColor: Colors.white24,
          backgroundImage: (photo != null && photo.length > 100) ? MemoryImage(base64Decode(photo)) : null,
          child: photo == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
        );
      },
    );
  }

  Widget _buildDailyQuests(List<TaskModel> tasks) {
    final pendingTasks = tasks.where((t) => !t.isCompleted).take(2).toList();
    return Column(
      children: [
        _buildSectionTitle("أهدافك القادمة"),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: pendingTasks.isEmpty 
            ? const Text("لا يوجد مهام حالية")
            : Column(children: pendingTasks.map((t) => ListTile(title: Text(t.title), leading: const Icon(Icons.star_border, color: Colors.amber))).toList()),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(int xp) {
    return Column(
      children: [
        _buildSectionTitle("الأوسمة المستحقة"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _badgeIcon(Icons.bolt, "سريع", xp > 100),
            _badgeIcon(Icons.verified_user, "موثق", xp > 500),
            _badgeIcon(Icons.workspace_premium, "خبير", xp > 1000),
          ],
        ),
      ],
    );
  }

  Widget _badgeIcon(IconData icon, String label, bool active) => Column(
    children: [
      Icon(icon, color: active ? Colors.amber : Colors.grey, size: 30),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );

  Widget _buildSectionTitle(String title) => Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))));

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, color: color), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1)]),
      ),
    );
  }

  Widget _buildInfoSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white, borderRadius: BorderRadius.circular(25)),
    child: Column(
      children: [
        _infoRow(Icons.email, "البريد", user?.email ?? ""),
        const Divider(),
        _infoRow(Icons.phone, "الهاتف", _isPhoneVisible ? "+966 5x xxx xxxx" : "xxxx xxx xxxx", trailing: IconButton(onPressed: () => setState(() => _isPhoneVisible = !_isPhoneVisible), icon: Icon(_isPhoneVisible ? Icons.visibility_off : Icons.visibility, size: 18))),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String t, String v, {Widget? trailing}) => ListTile(leading: Icon(icon, size: 20, color: const Color(0xFF6B4EFF)), title: Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)), subtitle: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), trailing: trailing);
}