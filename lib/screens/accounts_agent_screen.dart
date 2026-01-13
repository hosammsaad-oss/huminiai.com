import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humini_ai/services/groq_service.dart';
class AccountsAgentScreen extends StatefulWidget {
  const AccountsAgentScreen({super.key});

  @override
  State<AccountsAgentScreen> createState() => _AccountsAgentScreenState();
}

class _AccountsAgentScreenState extends State<AccountsAgentScreen> {
  // 1. البيانات والمتغيرات
  double totalBalance = 5420.50;
  double monthlyExpenses = 1200.00;
  bool isAutoTrackingEnabled = false;
String aiInsight = "اضغط على تحديث الخطة للحصول على نصيحة مالية ذكية.";
  // 2. وظائف الذكاء الاصطناعي (AI Functions)
  
  // دالة إظهار النافذة المنبثقة
  void _showAIPlanDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF)),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.tajawal(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("تم", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF6B4EFF))),
          ),
        ],
      ),
    );
  }

  // دالة توليد خطة التوفير عبر Groq
  Future<void> _generateSavingsPlan() async {
    // 1. إظهار نافذة الانتظار
    _showAIPlanDialog("هوميني يفكر...", "جارٍ تحليل بياناتك المالية عبر ذكاء Groq الخارق...");
  
    
    // 2. تجميع البيانات الحالية
    String myData = """
    تحليل مالي للمستخدم:
    الرصيد المتوفر: $totalBalance ريال.
    إجمالي مصاريف الشهر: $monthlyExpenses ريال.
    آخر العمليات: مشتريات سوبر ماركت.
    الرجاء تقديم نصيحة توفير ذكية ومختصرة.
    """;

    try {
      // 3. استدعاء السيرفس الخاص بك (إنشاء نسخة لأن الدوال ليست static)
      final groq = GroqService();
      String aiResponse = await groq.getAIResponse(myData);

      // 4. تحديث الواجهة بالرد الحقيقي
      if (mounted) {
        Navigator.pop(context); // إغلاق نافذة الانتظار
        _showAIPlanDialog("نصيحة هوميني الذكية", aiResponse);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showAIPlanDialog("خطأ", "لم يستطع الوكيل الاتصال بـ Groq، تأكد من الإنترنت ومفتاح الـ API.");
      }
    }
  }
    





  // 3. وظائف العمليات (Transactions & SMS)
  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("إضافة عملية جديدة",
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  labelText: "المبلغ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                  labelText: "بيان الصرف (مثلاً: بنزين، مطعم)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => Navigator.pop(context),
              child: Text("حفظ العملية", style: GoogleFonts.tajawal(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _startListeningToBankSMS() {
    print("بدأ الاستماع للرسائل البنكية...");
  }

  void _analyzeSMSWithAI(String smsText) async {
    setState(() {
      print("تم رصد عملية شراء جديدة وتحليلها: $smsText");
    });
  }

  // 4. بناء الواجهة الرئيسية (Main UI)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("وكيل الحسابات الذكي",
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 25),
              _buildAutoTrackingSwitch(),
              const SizedBox(height: 25),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("التحليل الذكي للهوميني",
                      style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _generateSavingsPlan,
                    icon: const Icon(Icons.bolt, size: 18, color: Color(0xFF6B4EFF)),
                    label: Text("تحديث الخطة", 
                      style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              





              
              const SizedBox(height: 15),
              _buildAIInsightCard(),
              const SizedBox(height: 25),
              Text("آخر العمليات",
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTransaction(context),
      ),
    );
  }

  // 5. مكونات الواجهة الفرعية (Sub-Widgets)

  Widget _buildAutoTrackingSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple.shade400),
          const SizedBox(width: 15),
          Expanded(
            child: Text("الرصد الذكي (SMS)", style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: isAutoTrackingEnabled,
            activeColor: const Color(0xFF6B4EFF),
            onChanged: (val) {
              setState(() {
                isAutoTrackingEnabled = val;
                if (val) _startListeningToBankSMS();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Text("إجمالي الرصيد المتوفر", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text("${totalBalance.toStringAsFixed(2)} ريال",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat("المصاريف", "$monthlyExpenses", Icons.arrow_downward),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMiniStat("الدخل", "7500", Icons.arrow_upward),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            Text(label, style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12)),
          ],
        ),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "لقد أنفقت 20% أكثر على المطاعم هذا الأسبوع. ننصحك بتقليل الطلبات الخارجية للتوفير.",
              style: GoogleFonts.tajawal(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0EDFF),
              child: Icon(Icons.shopping_bag, color: Color(0xFF6B4EFF))),
          title: Text("مشتريات سوبر ماركت", style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
          subtitle: Text("12 يناير 2026", style: GoogleFonts.tajawal(fontSize: 12)),
          trailing: Text("-150 ريال", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}