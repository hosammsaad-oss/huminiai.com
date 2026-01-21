import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/life_provider.dart';
import 'package:screenshot/screenshot.dart'; // استيراد حزمة لقطة الشاشة
import 'package:share_plus/share_plus.dart'; // استيراد حزمة المشاركة
import 'package:path_provider/path_provider.dart'; // لحفظ الصورة مؤقتاً
import 'dart:io'; // للتعامل مع الملفات

class StatsDashboard extends ConsumerWidget {
  const StatsDashboard({super.key});

  // متحكم التقاط الشاشة (هذا يجب أن يكون في مكان يمكن الوصول إليه من دالة المشاركة)
  // ونظراً لأن ConsumerWidget ثابت (const), سنعرفه داخل دالة المشاركة مباشرة أو نجعله متغيرًا عاديًا
  // أو نمرره كـ parameter إذا كان الويدجت stateful.
  // في هذه الحالة، سنستخدمه مباشرة ضمن دالة التقاط الـ Widget.

  // دالة المشاركة الجديدة
  Future<void> _shareReport(BuildContext context, WidgetRef ref) async {
    // عرض مؤشر تحميل
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "جاري إعداد تقريرك للمشاركة... 🚀",
          style: GoogleFonts.tajawal(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // نستخدم ScreenshotController جديد هنا لأنه داخل ConsumerWidget
    final ScreenshotController tempScreenshotController =
        ScreenshotController();

    // جلب بيانات التقرير والرتبة مرة واحدة
    final reportText = ref.read(lifeProvider.notifier).generateWeeklyReport();
    final userRank = ref.read(userRankProvider).value ?? "مبتدئ طموح 🌱";

    // التقاط لقطة شاشة للويدجت (نستخدم _buildShareableReportCard لإنشاء تصميم نظيف للمشاركة)
    final imageBytes = await tempScreenshotController.captureFromWidget(
      Directionality(
        // مهم جداً لدعم RTL في لقطة الشاشة
        textDirection: TextDirection.rtl,
        child: Material(
          color: Colors.transparent, // مهم لجعل الخلفية شفافة
          child: _buildShareableReportCard(reportText, userRank),
        ),
      ),
      delay: const Duration(milliseconds: 100), // تأخير بسيط للرسم
      pixelRatio: 3.0, // جودة أعلى للصورة الملتقطة
    );

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File(
      '${directory.path}/humaini_report.png',
    ).create();
    await imagePath.writeAsBytes(imageBytes);

    // مشاركة الصورة
    await Share.shareXFiles([
      XFile(imagePath.path),
    ], text: "إنجازاتي هذا الأسبوع مع هيوميني! 🌟\n#هيوميني #إنجازاتي");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(lifeProvider);
    final userRankAsync = ref.watch(userRankProvider); // لمراقبة الرتبة

    int total = tasks.length;
    int completed = tasks.where((t) => t.isCompleted).length;
    int remaining = total - completed;
    double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "لوحة التحكم والإنجاز",
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildEnergyMeter(progress),
            const SizedBox(height: 25),

            // --- بطاقة التقرير الذكي مع زر المشاركة ---
            userRankAsync.when(
              data: (rank) => _buildAIReportCard(ref, rank, context),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  "خطأ: $err",
                  style: GoogleFonts.tajawal(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                _buildStatCard(
                  "المنجزة",
                  "$completed",
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "المتبقية",
                  "$remaining",
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatCard(
                  "الإجمالي",
                  "$total",
                  Icons.list_alt,
                  Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "الاستمرارية",
                  "5 أيام",
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 25),

            _buildCategoryBreakdown(tasks),
          ],
        ),
      ),
    );
  }

  // --- دالة بناء بطاقة التقرير الذكي (UI الذي يظهر في التطبيق) ---
  Widget _buildAIReportCard(
    WidgetRef ref,
    String userRank,
    BuildContext context,
  ) {
    final reportText = ref.watch(lifeProvider.notifier).generateWeeklyReport();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.deepPurple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: Colors.deepPurpleAccent,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                "تحليل هيوميني الذكي ✨",
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reportText,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          // عرض رتبة المستخدم
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "رتبتك الحالية: $userRank",
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // زر المشاركة
          Center(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _shareReport(context, ref), // استدعاء دالة المشاركة
              icon: const Icon(Icons.share, color: Colors.white),
              label: Text(
                "شارك إنجازاتك الآن!",
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- دالة جديدة: تصميم البطاقة التي سيتم التقاط لقطة شاشة لها (للمشاركة فقط) ---
  // هذه الدالة لا تحتوي على زر المشاركة ولا تتأثر بالـ ref لتكون "نظيفة" للالتقاط
  Widget _buildShareableReportCard(String reportText, String userRank) {
    return Container(
      width: 300, // حجم ثابت للصورة الملتقطة
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.deepPurple.shade100,
          ], // تدرج لوني أفتح للمشاركة
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // مهم لجعل حجم الكارد مناسب للمحتوى
        children: [
          Text(
            "تقـرير هيومـيني الذكـي 🌟",
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reportText,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "رتبتك الحالية: $userRank",
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // يمكنك إضافة شعار التطبيق هنا
          Align(
            alignment: Alignment.center,
            child: Text(
              "#HumainiApp",
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMeter(double progress) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "مؤشر الإنجاز الكلي",
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.pie_chart_rounded,
                color: Colors.purple[300],
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  backgroundColor: Colors.grey[100],
                  color: progress > 0.7
                      ? Colors.greenAccent[700]
                      : Colors.deepPurpleAccent,
                ),
              ),
              Column(
                children: [
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "مكتمل",
                    style: GoogleFonts.tajawal(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            progress >= 0.8
                ? "أداء مذهل! أنت في المنطقة الخضراء 🌟"
                : "كل خطوة صغيرة تقربك من هدفك الكبير.",
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<TaskModel> tasks) {
    int daily = tasks.where((t) => t.category == 'daily').length;
    int weekly = tasks.where((t) => t.category == 'weekly').length;
    int monthly = tasks.where((t) => t.category == 'monthly').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "توزيع خطة العمل",
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildTinyBar("المهام اليومية", daily, Colors.blue),
          _buildTinyBar("المهام الأسبوعية", weekly, Colors.purple),
          _buildTinyBar("المهام الشهرية", monthly, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildTinyBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: GoogleFonts.tajawal(fontSize: 12)),
          ),
          Expanded(
            flex: 7,
            child: LinearProgressIndicator(
              value: count == 0 ? 0 : (count / 10).clamp(0.0, 1.0),
              color: color,
              backgroundColor: Colors.grey[100],
            ),
          ),
          const SizedBox(width: 10),
          Text("$count", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
