import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductivityStatsScreen extends StatelessWidget {
  const ProductivityStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تحليل الإنتاجية 📊", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInsightCard(),
              const SizedBox(height: 30),
              Text("مستوى الإنجاز الأسبوعي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _buildLineChart(),
              const SizedBox(height: 40),
              _buildActivityDistribution(),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة "نصيحة الذكاء الاصطناعي" بناءً على البيانات
  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "تحليل هوميني: ذروة إنتاجيتك تكون يوم الثلاثاء صباحاً. ننصحك بجدولة مهامك الصعبة في هذا الوقت!",
              style: GoogleFonts.tajawal(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // رسم بياني (خطي) للإنتاجية
  Widget _buildLineChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3), // السبت
                const FlSpot(1, 4), // الأحد
                const FlSpot(2, 2), // الاثنين
                const FlSpot(3, 7), // الثلاثاء (الذروة)
                const FlSpot(4, 5), // الأربعاء
                const FlSpot(5, 4), // الخميس
                const FlSpot(6, 6), // الجمعة
              ],
              isCurved: true,
              color: const Color(0xFF6B4EFF),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // توزيع النشاطات (رسم دائري)
  Widget _buildActivityDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("توزيع نشاطك", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: 40, color: Colors.purple, title: "عمل", radius: 50, titleStyle: const TextStyle(color: Colors.white)),
                PieChartSectionData(value: 30, color: Colors.blue, title: "تطوير", radius: 50, titleStyle: const TextStyle(color: Colors.white)),
                PieChartSectionData(value: 30, color: Colors.green, title: "صحة", radius: 50, titleStyle: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}