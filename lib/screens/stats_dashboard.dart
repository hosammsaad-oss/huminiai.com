import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/life_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/fl_chart.dart'; // <--- أضف هذا السطر

class StatsDashboard extends ConsumerWidget {
  const StatsDashboard({super.key});
  // --- أضف هاتين الدالتين في نهاية الكلاس قبل القوس الأخير } ---

  Widget _buildRadarChart(List<TaskModel> tasks) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: Colors.deepPurple.withOpacity(0.4),
              borderColor: Colors.deepPurple,
              dataEntries: [
                RadarEntry(value: _getScore(tasks, 'تطور')),
                RadarEntry(value: _getScore(tasks, 'التزام')),
                RadarEntry(value: _getScore(tasks, 'سرعة')),
                RadarEntry(value: _getScore(tasks, 'تواصل')),
                RadarEntry(value: _getScore(tasks, 'دقة')),
              ],
            ),
          ],
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return const RadarChartTitle(text: 'تطور');
              case 1:
                return const RadarChartTitle(text: 'التزام');
              case 2:
                return const RadarChartTitle(text: 'سرعة');
              case 3:
                return const RadarChartTitle(text: 'تواصل');
              case 4:
                return const RadarChartTitle(text: 'دقة');
              default:
                return const RadarChartTitle(text: '');
            }
          },
        ),
      ),
    );
  }

  double _getScore(List<TaskModel> tasks, String category) {
    final categoryTasks = tasks.where((t) => t.category == category).toList();
    if (categoryTasks.isEmpty) return 2.0;
    final completed = categoryTasks.where((t) => t.isCompleted).length;
    return (completed / categoryTasks.length) * 10;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(lifeProvider);
    // ابحث عن Column وأضف هذا السطر بداخله:
    children:
    [
      _buildRadarChart(tasks), // <--- هذا يستدعي الرسم البياني
      const SizedBox(height: 20),
      // ... باقي العناصر مثل بطاقة التحليل
    ];
    // حساب البيانات الحقيقية من قاعدة البيانات
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
            // 1. مؤشر الطاقة النفسية والذهنية (Mental Energy)
            _buildEnergyMeter(progress),
            const SizedBox(height: 25),

            // 2. شبكة الإحصائيات السريعة
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

            // 3. تحليل خطة العمل (يومي/أسبوعي/شهري)
            _buildCategoryBreakdown(tasks),
          ],
        ),
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
          // الرسم البياني الدائري المخصص
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
              value: count / 10,
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

Widget _buildRadarChart(List<TaskModel> tasks) {
  // حساب البيانات للرسم البياني (نسبة الإنجاز لكل فئة)
  return Container(
    height: 250,
    padding: const EdgeInsets.all(10),
    child: RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Colors.deepPurple.withOpacity(0.4),
            borderColor: Colors.deepPurple,
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: _getScore(tasks, 'تطور')),
              RadarEntry(value: _getScore(tasks, 'التزام')),
              RadarEntry(value: _getScore(tasks, 'سرعة')),
              RadarEntry(value: _getScore(tasks, 'تواصل')),
              RadarEntry(value: _getScore(tasks, 'دقة')),
            ],
          ),
        ],
        getTitle: (index, angle) {
          switch (index) {
            case 0:
              return RadarChartTitle(text: 'تطور');
            case 1:
              return RadarChartTitle(text: 'التزام');
            case 2:
              return RadarChartTitle(text: 'سرعة');
            case 3:
              return RadarChartTitle(text: 'تواصل');
            case 4:
              return RadarChartTitle(text: 'دقة');
            default:
              return const RadarChartTitle(text: '');
          }
        },
      ),
    ),
  );
}

double _getScore(List<TaskModel> tasks, String category) {
  final categoryTasks = tasks.where((t) => t.category == category).toList();
  if (categoryTasks.isEmpty) return 0.0;
  final completed = categoryTasks.where((t) => t.isCompleted).length;
  return (completed / categoryTasks.length) * 10; // مقياس من 10
}
