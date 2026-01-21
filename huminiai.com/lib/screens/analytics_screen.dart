import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // المكتبة الجديدة للرسم البياني
import '../providers/life_provider.dart';
import '../providers/goals_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(lifeProvider);
    final goals = ref.watch(goalsProvider);

    // حسابات الإنجاز
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final taskProgress = tasks.isEmpty ? 0.0 : completedTasks / tasks.length;
    
    // نظام الـ XP الافتراضي (يمكنك لاحقاً ربطه بـ Provider حقيقي)
    final totalXP = completedTasks * 50; 

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: Text("تحليلات يوني كورن", 
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4EFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. بطاقة الـ XP الجديدة (ميزة اليوني كورن)
              _buildXPRankCard(totalXP),
              
              const SizedBox(height: 25),
              
              // 2. بطاقة إنجاز المهام (التي كانت لديك مع تحسين التصميم)
              _buildMainStatCard("إنجاز المهام اليومية", taskProgress, "${(taskProgress * 100).toInt()}%"),
              
              const SizedBox(height: 30),
              
              // 3. مخطط توازن الحياة الذكي (الرادار)
              Text("توازن جوانب حياتك", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              _buildLifeBalanceChart(),

              const SizedBox(height: 30),

              // 4. قائمة الأهداف الإستراتيجية (مع الحفاظ على ميزتك السابقة)
              Text("تقدم الأهداف الإستراتيجية", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ...goals.map((g) => _buildGoalItem(g.title, g.progress)),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة رتبة المستخدم والـ XP
  Widget _buildXPRankCard(int xp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("رتبة المنتج الذكي", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text("$xp XP", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 50),
        ],
      ),
    );
  }

  // تحسين للـ StatCard الأصلية الخاصة بك
  Widget _buildMainStatCard(String title, double value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 70, width: 70,
            child: CircularProgressIndicator(
              value: value, 
              color: const Color(0xFF6B4EFF), 
              strokeWidth: 8, 
              backgroundColor: const Color(0xFFF0EDFF),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: GoogleFonts.poppins(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  // ميزة مخطط الرادار
  Widget _buildLifeBalanceChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF6B4EFF).withOpacity(0.2),
              borderColor: const Color(0xFF6B4EFF),
              entryRadius: 3,
              dataEntries: [
                const RadarEntry(value: 3), // العمل
                const RadarEntry(value: 2), // الصحة
                const RadarEntry(value: 4), // التعلم
                const RadarEntry(value: 3.5), // العائلة
                const RadarEntry(value: 2.5), // الرياضة
              ],
            ),
          ],
          radarShape: RadarShape.circle,
          getTitle: (index, angle) {
            switch (index) {
              case 0: return const RadarChartTitle(text: 'العمل');
              case 1: return const RadarChartTitle(text: 'الصحة');
              case 2: return const RadarChartTitle(text: 'التعلم');
              case 3: return const RadarChartTitle(text: 'العائلة');
              case 4: return const RadarChartTitle(text: 'الرياضة');
              default: return const RadarChartTitle(text: '');
            }
          },
        ),
      ),
    );
  }

  // تحسين لشكل عرض الأهداف
  Widget _buildGoalItem(String title, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.tajawal(fontSize: 14)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, color: const Color(0xFF6B4EFF), backgroundColor: const Color(0xFFF0EDFF), minHeight: 6),
          ),
        ],
      ),
    );
  }
}