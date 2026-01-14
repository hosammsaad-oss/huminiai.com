import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humini_ai/services/groq_service.dart';
import 'package:telephony/telephony.dart';
import 'package:fl_chart/fl_chart.dart'; // تأكد من إضافة fl_chart في pubspec.yaml
import 'package:workmanager/workmanager.dart';



@pragma('vm:entry-point') // ضروري جداً لكي يعمل الكود والتطبيق مغلق
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // هنا نضع الكود الذي نريده أن يعمل في الخلفية
    // سنقوم بتفعيل الاستماع للرسائل هنا
    return Future.value(true);
  });
}












// نموذج البيانات المطور ليشمل التصنيف
class Transaction {
  final String label;
  final double amount;
  final String category; // تم إضافة التصنيف
  final DateTime date;
  Transaction({required this.label, required this.amount, required this.category, required this.date});
}

class AccountsAgentScreen extends StatefulWidget {
  const AccountsAgentScreen({super.key});

  @override
  State<AccountsAgentScreen> createState() => _AccountsAgentScreenState();
}

class _AccountsAgentScreenState extends State<AccountsAgentScreen> {
  // 1. البيانات الأساسية
  double totalBalance = 5420.50;
  double monthlyExpenses = 1200.00;
  bool isAutoTrackingEnabled = false;
  String aiInsight = "اضغط على تحديث الخطة للحصول على نصيحة مالية ذكية.";

  // قائمة العمليات المحدثة
  List<Transaction> transactions = [
    Transaction(label: "مشتريات سوبر ماركت", amount: 150.0, category: "طعام", date: DateTime.now()),
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  
  final Telephony telephony = Telephony.instance;

  // دالة المحاكاة للاختبار على المتصفح (تأكد من عمل التصنيف)
  void _simulateIncomingSMS() {
    String fakeSMS = "مصرف الراجحي: شراء عبر مدى بقيمة 120.00 ريال لدى هرفي. الرصيد المتاح: 5300.50 ريال.";
    _analyzeSMSWithAI(fakeSMS);
  }

  // 2. دالة حفظ العملية يدوياً
 void _saveNewTransaction() {
    double? enteredAmount = double.tryParse(_amountController.text);
    String label = _labelController.text;

    if (enteredAmount != null && enteredAmount > 0 && label.isNotEmpty) {
      setState(() {
        totalBalance -= enteredAmount;
        monthlyExpenses += enteredAmount;
        
        // هنا أضفنا التصنيف "عام" ليتوافق مع النموذج الجديد
        transactions.insert(0, Transaction(
          label: label, 
          amount: enteredAmount, 
          category: "عام", 
          date: DateTime.now()
        ));
        
        _amountController.clear();
        _labelController.clear();
      });
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ $label بنجاح ✅", style: GoogleFonts.tajawal()), 
          backgroundColor: Colors.green
        ),
      );
    }
  }

  // 3. وظائف الرصد الذكي (SMS Tracking) المحدثة بالتصنيف
  void _startListeningToBankSMS() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;

    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          String body = message.body ?? "";
          if (body.contains("شراء") || body.contains("خصم") || body.contains("Purchase") || body.contains("تأكيد")) {
            _analyzeSMSWithAI(body);
          }
        },
        listenInBackground: false,
      );
    } else {
      setState(() => isAutoTrackingEnabled = false);
    }
  }

  void _analyzeSMSWithAI(String smsText) async {
    try {
      final groq = GroqService();
      // برومبت مطور يطلب التصنيف أيضاً
      String prompt = "استخرج المبلغ (أرقام فقط)، والمتجر، والتصنيف (طعام، ترفيه، تسوق، فواتير، أو أخرى) من هذه الرسالة: $smsText. رد بصيغة: المبلغ | المتجر | التصنيف";
      String response = await groq.getAIResponse(prompt);

      List<String> parts = response.split('|');
      if (parts.length == 3) {
        double? amount = double.tryParse(parts[0].trim());
        String label = parts[1].trim();
        String category = parts[2].trim();

        if (amount != null) {
          setState(() {
            totalBalance -= amount;
            monthlyExpenses += amount;
            transactions.insert(0, Transaction(label: label, amount: amount, category: category, date: DateTime.now()));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("رصد ذكي ($category): $label ✅"), backgroundColor: const Color(0xFF6B4EFF)),
          );
        }
      }
    } catch (e) {
      print("خطأ: $e");
    }
  }

  // دالة بناء أقسام الرسم البياني
  List<PieChartSectionData> _getChartSections() {
    Map<String, double> data = {};
    for (var t in transactions) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }
    List<Color> colors = [Colors.purple, Colors.orange, Colors.blue, Colors.red, Colors.green];
    int i = 0;
    return data.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(color: color, value: e.value, title: e.key, radius: 40, titleStyle: GoogleFonts.tajawal(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold));
    }).toList();
  }

  // 4. وظائف الذكاء الاصطناعي (خطة التوفير)
  Future<void> _generateSavingsPlan() async {
    _showAIPlanDialog("هوميني يفكر...", "جارٍ تحليل بياناتك المالية عبر ذكاء Groq الخارق...");
    try {
      final groq = GroqService();
      String aiResponse = await groq.getAIResponse("الرصيد: $totalBalance، المصاريف: $monthlyExpenses. أعطني نصيحة توفير.");
      if (mounted) {
        setState(() => aiInsight = aiResponse);
        Navigator.pop(context);
        _showAIPlanDialog("نصيحة هوميني الذكية", aiResponse);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showAIPlanDialog("خطأ", "لم يستطع الوكيل الاتصال بـ Groq.");
      }
    }
  }

  void _showAIPlanDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: SingleChildScrollView(child: Text(content, style: GoogleFonts.tajawal(height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("تم", style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF)))),
        ],
      ),
    );
  }

  // 5. بناء الواجهة الرئيسية
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("وكيل الحسابات الذكي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
              _buildChartSection(), // الرسم البياني الجديد
              const SizedBox(height: 25),
              _buildAutoTrackingSwitch(),
              Center(
                child: TextButton.icon(
                  onPressed: _simulateIncomingSMS,
                  icon: const Icon(Icons.science, size: 16, color: Colors.grey),
                  label: Text("محاكاة عملية تجريبية", style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 15),
              _buildSectionHeader("التحليل الذكي للهوميني", _generateSavingsPlan),
              const SizedBox(height: 15),
              _buildAIInsightCard(),
              const SizedBox(height: 25),
              Text("آخر العمليات المصنفة", style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
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

  // مكون الرسم البياني
  Widget _buildChartSection() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(child: PieChart(PieChartData(sections: _getChartSections(), centerSpaceRadius: 35))),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("توزيع الفئات", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              Text("تحليل ذكي", style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  // باقي مكونات التصميم كما هي دون تغيير
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Text("إجمالي الرصيد المتوفر", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text("${totalBalance.toStringAsFixed(2)} ريال", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat("المصاريف", monthlyExpenses.toStringAsFixed(2), Icons.arrow_downward),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMiniStat("الدخل", "7500.00", Icons.arrow_upward),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(children: [
      Row(children: [Icon(icon, size: 14, color: Colors.white70), const SizedBox(width: 4), Text(label, style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12))]),
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildAutoTrackingSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF)),
          const SizedBox(width: 15),
          Expanded(child: Text("الرصد الذكي (SMS)", style: GoogleFonts.tajawal(fontWeight: FontWeight.w600))),
          Switch(value: isAutoTrackingEnabled, activeThumbColor: const Color(0xFF6B4EFF), onChanged: (v) {
              setState(() => isAutoTrackingEnabled = v);
              if (v) _startListeningToBankSMS();
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: onAction, icon: const Icon(Icons.bolt, color: Color(0xFF6B4EFF)), label: Text("تحديث الخطة", style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber),
          const SizedBox(width: 15),
          Expanded(child: Text(aiInsight, style: GoogleFonts.tajawal(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF0EDFF), 
            child: Text(_getEmoji(t.category), style: const TextStyle(fontSize: 18)),
          ),
          title: Text(t.label, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
          subtitle: Text("${t.category} - ${t.date.day}/${t.date.month}", style: GoogleFonts.tajawal(fontSize: 12)),
          trailing: Text("-${t.amount.toStringAsFixed(2)} ريال", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  String _getEmoji(String category) {
    if (category.contains("طعام")) return "🍔";
    if (category.contains("ترفيه")) return "🎮";
    if (category.contains("تسوق")) return "🛍️";
    if (category.contains("فواتير")) return "📄";
    return "💰";
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("إضافة عملية جديدة", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "المبلغ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: _labelController, decoration: InputDecoration(labelText: "بيان الصرف", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _saveNewTransaction,
              child: Text("حفظ العملية", style: GoogleFonts.tajawal(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}