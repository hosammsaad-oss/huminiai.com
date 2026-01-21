import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humini_ai/services/groq_service.dart';
import 'package:telephony/telephony.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return Future.value(true);
  });
}

class Transaction {
  final String label;
  final double amount;
  final String category;
  final DateTime date;
  Transaction({required this.label, required this.amount, required this.category, required this.date});
}

class AccountsAgentScreen extends StatefulWidget {
  const AccountsAgentScreen({super.key});

  @override
  State<AccountsAgentScreen> createState() => _AccountsAgentScreenState();
  
}

class _AccountsAgentScreenState extends State<AccountsAgentScreen> {
  bool isAutoTrackingEnabled = false;
  String aiInsight = "اضغط على تحديث الخطة للحصول على نصيحة مالية ذكية.";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _vaultController = TextEditingController();
  final Telephony telephony = Telephony.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;


@override
  void initState() {
    super.initState();
    _setupFirebaseMessaging(); // تهيئة الإشعارات عند بدء التشغيل
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب إذن من المستخدم لإرسال إشعارات (خاصة بـ iOS و Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // الحصول على "Token" الجهاز (هذا هو عنوان الهاتف الذي نرسل إليه)
      String? token = await messaging.getToken();
      print("Device Token: $token"); // ستحتاج هذا لإرسال تنبيهات تجريبية
    }

    // استلام التنبيه والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showSmartNotification(
          message.notification!.title ?? "تنبيه من هوميني",
          message.notification!.body ?? "",
          const Color(0xFF6B4EFF)
        );
      }
    });
  }
Future<void> _updateFinancialGoal(double newTarget) async {
  if (userId == null) return;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('goals')
      .doc('primary_goal')
      .set({
    'target': newTarget,
    'title': 'الميزانية الشهرية',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تحديث ميزانيتك الجديدة: $newTarget ريال 🎯", style: GoogleFonts.tajawal())),
    );
  }
}

  // --- دالات Firestore ---
  Future<void> _addTransactionToFirestore(String label, double amount, String category) async {
    if (userId == null) return;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add({
      'label': label,
      'amount': amount,
      'category': category,
      'date': FieldValue.serverTimestamp(),
    });

    _checkBudgetExceeding();
  }

  // --- نظام الخزنة الجديد (Vault) ---

  Future<void> _transferToVault(double amount) async {
    if (userId == null || amount <= 0) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('vault')
        .add({
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
      'note': 'تحويل يدوي للخزنة'
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم إيداع $amount ريال في خزنتك بنجاح! 💰", style: GoogleFonts.tajawal()),
          backgroundColor: Colors.amber[800],
        ),
      );
    }
    Future<void> updateFinancialGoal(double newTarget) async {
  if (userId == null) return;
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('goals')
      .doc('primary_goal')
      .set({
    'target': newTarget,
    'title': 'الميزانية الشهرية',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تحديث ميزانيتك الجديدة: $newTarget ريال 🎯", style: GoogleFonts.tajawal())),
    );
  }
Future<void> updateFinancialGoal(double newTarget) async {
  if (userId == null) return;
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('goals')
      .doc('primary_goal')
      .set({
    'target': newTarget,
    'title': 'الميزانية الشهرية',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تحديث ميزانيتك الجديدة: $newTarget ريال 🎯", style: GoogleFonts.tajawal())),
    );
  }
}

}
  }

  // --- دالات الحارس الذكي والتنبيهات ---

  Future<void> _checkBudgetExceeding() async {
    if (userId == null) return;

    var goalDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc('primary_goal')
        .get();

    if (goalDoc.exists) {
      double target = (goalDoc.data()!['target'] as num).toDouble();
      
      var transSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      double totalSpent = 0;
      for (var doc in transSnapshot.docs) {
        totalSpent += (doc.data()['amount'] as num).toDouble();
      }

      double usagePercentage = (totalSpent / target);

      if (usagePercentage >= 0.8 && usagePercentage < 1.0) {
        _showUrgentAlert("⚠️ تنبيه الميزانية", "حسام، لقد استهلكت أكثر من 80% من ميزانية هدفك! انتبه لمصاريفك القادمة.");
      } else if (usagePercentage >= 1.0) {
        _showUrgentAlert("🚨 تجاوزت الحد!", "لقد تخطيت ميزانية الهدف المحددة بالكامل. هوميني يقترح مراجعة فورية لخطة الصرف.");
      }
    }
  }

  void _showUrgentAlert(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.tajawal(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // --- نظام تحدي التوفير ---

  Future<void> _startSavingsChallenge() async {
    _showAIPlanDialog("هوميني يصمم تحديك...", "يتم تحليل نمط صرفك لإنشاء تحدي توفير مخصص لك يا حسام.");
    try {
      final groq = GroqService();
      String prompt = "المستخدم حسام يريد تحدي توفير للأسبوع القادم. اقترح 'مبلغاً واقعياً' للتوفير وهدفاً صغيراً. الرد يجب أن يكون مشجعاً وقصيراً جداً.";
      
      String challenge = await groq.getAIResponse(prompt);
      if (mounted) {
        Navigator.pop(context);
        _showAIPlanDialog("🎯 تحدي الأسبوع", challenge);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // --- نظام التقارير الأسبوعية ---

  Future<void> _generateWeeklyReport() async {
    if (userId == null) return;
    _showAIPlanDialog("هوميني يجهز تقريرك...", "جارٍ جمع وتحليل بيانات الأسبوع الماضي...");

    try {
      DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      var transSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      String transactionsSummary = "";
      double weeklyTotal = 0;
      for (var doc in transSnapshot.docs) {
        weeklyTotal += doc['amount'];
        transactionsSummary += "${doc['label']} (${doc['amount']} ريال)، ";
      }

      final groq = GroqService();
      String prompt = """
      حلل هذا السجل المالي للأسبوع الماضي للمستخدم 'حسام': إجمالي الصرف: $weeklyTotal ريال. اكتب تقريراً أسبوعياً قصيراً جداً، مشجعاً.
      """;

      String report = await groq.getAIResponse(prompt);
      
      if (mounted) {
        Navigator.pop(context); 
        _showAIPlanDialog("تقرير هوميني الأسبوعي", report);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // --- دالات الرصد والتحليل ---

  void _simulateIncomingSMS() {
    String fakeSMS = "مصرف الراجحي: شراء عبر مدى بقيمة 120.00 ريال لدى هرفي. الرصيد المتاح: 5300.50 ريال.";
    _analyzeSMSWithAI(fakeSMS);
  }

  void _analyzeSMSWithAI(String smsText) async {
    try {
      final groq = GroqService();
      String prompt = "استخرج المبلغ (أرقام فقط)، والمتجر، والتصنيف من هذه الرسالة: $smsText. رد بصيغة: المبلغ | المتجر | التصنيف";
      String response = await groq.getAIResponse(prompt);

      List<String> parts = response.split('|');
      if (parts.length == 3) {
        double? amount = double.tryParse(parts[0].trim());
        String label = parts[1].trim();
        String category = parts[2].trim();

        if (amount != null) {
          await _addTransactionToFirestore(label, amount, category);
        }
      }
    } catch (e) {
      debugPrint("خطأ في تحليل AI: $e");
    }
  }

  void _startListeningToBankSMS() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          String body = message.body ?? "";
          if (body.contains("شراء") || body.contains("خصم") || body.contains("Purchase")) {
            _analyzeSMSWithAI(body);
          }
        },
        listenInBackground: false,
      );
    } else {
      setState(() => isAutoTrackingEnabled = false);
    }
  }

 void _saveNewTransaction() async {
    double? enteredAmount = double.tryParse(_amountController.text);
    String label = _labelController.text;

    if (enteredAmount != null && enteredAmount > 0 && label.isNotEmpty) {
      await _addTransactionToFirestore(label, enteredAmount, "عام");
      
      // جلب الميزانية الحالية لتفعيل التنبيه
      var goalDoc = await FirebaseFirestore.instance.collection('users').doc(userId).collection('goals').doc('primary_goal').get();
      if (goalDoc.exists) {
        double target = (goalDoc.data()!['target'] as num).toDouble();
        
        // جلب إجمالي المصاريف بعد الإضافة الجديدة
        var transSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection('transactions').get();
        double total = 0;
        for (var doc in transSnapshot.docs) {
          total += (doc.data()['amount'] as num).toDouble();
        }

        // تفعيل التنبيه الذكي
        _checkBudgetStatusAndNotify(total, target);
      }

      _amountController.clear();
      _labelController.clear();
      if (mounted) Navigator.pop(context);
    }
  }
   
  // --- دالات الذكاء الاصطناعي ---

  Future<void> _generateAIAdviceWithGoal(double expenses, double target) async {
    _showAIPlanDialog("هوميني يحلل هدفك...", "جارٍ مقارنة مصاريفك مع هدف التوفير المخطط له...");
    try {
      final groq = GroqService();
      String prompt = "المستخدم حسام لديه هدف $target وصرف $expenses. أعط نصيحة قصيرة جداً.";
      
      String aiResponse = await groq.getAIResponse(prompt);
      if (mounted) {
        setState(() => aiInsight = aiResponse);
        Navigator.pop(context); 
        _showAIPlanDialog("نصيحة هوميني الذكية", aiResponse);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
          Expanded(child: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18))),
        ]),
        content: SingleChildScrollView(child: Text(content, style: GoogleFonts.tajawal(height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("تم", style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF)))),
        ],
      ),
    );
  }

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
        child: StreamBuilder<QuerySnapshot>(
          
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            List<Transaction> liveTransactions = [];
            double currentExpenses = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final t = Transaction(
                  label: data['label'] ?? '',
                  amount: (data['amount'] as num).toDouble(),
                  category: data['category'] ?? 'عام',
                  date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                );
                liveTransactions.add(t);
                currentExpenses += t.amount;
              }
            }
if (currentExpenses > 0) {
  // هذا سيجعل التطبيق يراقب الحالة بمجرد التحميل
}
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(7500.0 - currentExpenses, currentExpenses),
                  const SizedBox(height: 15),
                  
                  // --- عرض الخزنة (Vault Display) ---
                  _buildVaultCard(),

                  _buildVaultCard(),
                  _buildSmartComparisonInsight(currentExpenses),
                  const SizedBox(height: 20),
                  _buildChallengeCard(),
                  const SizedBox(height: 15),
                  const SizedBox(height: 20),
                  _buildSmartComparisonInsight(currentExpenses),
                  _buildChallengeCard(),
                  const SizedBox(height: 20),

                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('goals')
                        .doc('primary_goal')
                        .snapshots(),
                    builder: (context, goalSnapshot) {
                      if (!goalSnapshot.hasData || !goalSnapshot.data!.exists) {
                        return const SizedBox(); 
                      }
                      var goalData = goalSnapshot.data!.data() as Map<String, dynamic>;
                      return _buildSavingsProgress(
                        goalData['title'] ?? "الهدف المالي", 
                        currentExpenses, 
                        (goalData['target'] as num).toDouble()
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  _buildChartSection(liveTransactions),
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
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderButton("تحديث الخطة", Icons.bolt, () async {
                           var goalDoc = await FirebaseFirestore.instance.collection('users').doc(userId).collection('goals').doc('primary_goal').get();
                           if (goalDoc.exists) {
                             double target = (goalDoc.data()!['target'] as num).toDouble();
                             _generateAIAdviceWithGoal(currentExpenses, target);
                           }
                        }),
                        _buildHeaderButton("تقرير الأسبوع", Icons.summarize, _generateWeeklyReport),
                        _buildHeaderButton("إيداع بالخزنة", Icons.savings, () => _showVaultDeposit(context)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  _buildAIInsightCard(),
                  const SizedBox(height: 25),
                  Text("آخر العمليات المصنفة", style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildRecentTransactions(liveTransactions),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTransaction(context),
      ),
    );
  }

  // --- مكونات الواجهة الجديدة ---

  Widget _buildVaultCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vault')
          .snapshots(),
      builder: (context, snapshot) {
        double totalVault = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalVault += (doc.data() as Map<String, dynamic>)['amount'];
          }
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFDAA520)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("خزنة التوفير الذهبية", style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("${totalVault.toStringAsFixed(2)} ريال", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.lock, color: Colors.white, size: 40),
            ],
          ),
        );
      },
    );
  }

  void _showVaultDeposit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("إيداع في الخزنة", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(controller: _vaultController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "المبلغ المراد توفيره", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => _transferToVault(double.tryParse(_vaultController.text) ?? 0),
              child: Text("نقل إلى الخزنة", style: GoogleFonts.tajawal(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFE8E3FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.2))),
      child: Row(
        children: [
          const Text("🏅", style: TextStyle(fontSize: 30)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("تحدي الأسبوع", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: const Color(0xFF6B4EFF))),
            Text("وفر أكثر من 200 ريال لتحصل على وسام جديد!", style: GoogleFonts.tajawal(fontSize: 12, color: Colors.black54)),
          ])),
          ElevatedButton(onPressed: _startSavingsChallenge, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text("تفعيل", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12))),

        ],
      ),
    );
  }

  Widget _buildHeaderButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(padding: const EdgeInsets.only(left: 10), child: TextButton.icon(onPressed: onTap, icon: Icon(icon, color: const Color(0xFF6B4EFF), size: 18), label: Text(label, style: GoogleFonts.tajawal(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 13))));
  }

 Widget _buildSavingsProgress(String title, double currentExpenses, double targetGoal) {
    double progress = (currentExpenses / targetGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              // هذا هو الجزء المسؤول عن النص والأيقونة
              Row(
                children: [
                  Text("ميزانية $title", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  // أيقونة القلم للتعديل
                  InkWell(
                    onTap: () => _showEditGoalDialog(targetGoal),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note, color: Color(0xFF6B4EFF), size: 22),
                    ),
                  ),
                ],
              ),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: GoogleFonts.poppins(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10), 
            child: LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.grey[100], 
              color: progress > 0.9 ? Colors.red : const Color(0xFF6B4EFF), 
              minHeight: 8
            )
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0 ? "تجاوزت الميزانية المحددة!" : "متبقي ${ (targetGoal - currentExpenses).toStringAsFixed(0) } ريال للالتزام بخطتك", 
            style: GoogleFonts.tajawal(fontSize: 12, color: progress > 0.9 ? Colors.red : Colors.grey[600])
          ),
        ],
      ),
    );
  }


void _showEditGoalDialog(double currentTarget) {
  TextEditingController goalController = TextEditingController(text: currentTarget.toString());
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("تعديل الميزانية المستهدفة", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: goalController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          suffixText: "ريال",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء", style: GoogleFonts.tajawal(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => _updateFinancialGoal(double.tryParse(goalController.text) ?? currentTarget),
          child: Text("حفظ", style: GoogleFonts.tajawal(color: Colors.white)),
        ),
      ],
    ),
  );
}






  Widget _buildBalanceCard(double balance, double expenses) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 15)]),
      child: Column(children: [
        Text("إجمالي الرصيد المتوفر", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 10),
        Text("${balance.toStringAsFixed(2)} ريال", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildMiniStat("المصاريف", expenses.toStringAsFixed(2), Icons.arrow_downward),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildMiniStat("الدخل", "7500.00", Icons.arrow_upward),
        ])
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(children: [
      Row(children: [Icon(icon, size: 14, color: Colors.white70), const SizedBox(width: 4), Text(label, style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12))]),
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildChartSection(List<Transaction> transList) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        Expanded(child: PieChart(PieChartData(sections: _getChartSections(transList), centerSpaceRadius: 35))),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("توزيع الفئات", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          Text("تحليل ذكي", style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
        ])
      ]),
    );
  }

  List<PieChartSectionData> _getChartSections(List<Transaction> transList) {
    if (transList.isEmpty) return [PieChartSectionData(color: Colors.grey, value: 1, title: "لا بيانات", radius: 40)];
    Map<String, double> data = {};
    for (var t in transList) {
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

  Widget _buildAutoTrackingSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF)),
        const SizedBox(width: 15),
        Expanded(child: Text("الرصد الذكي (SMS)", style: GoogleFonts.tajawal(fontWeight: FontWeight.w600))),
        Switch(value: isAutoTrackingEnabled, activeThumbColor: const Color(0xFF6B4EFF), onChanged: (v) {
          setState(() => isAutoTrackingEnabled = v);
          if (v) _startListeningToBankSMS();
        }),
      ]),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.lightbulb, color: Colors.amber),
        const SizedBox(width: 15),
        Expanded(child: Text(aiInsight, style: GoogleFonts.tajawal(fontSize: 13, height: 1.5))),
      ]),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transList) {
    if (transList.isEmpty) return const Center(child: Text("لا توجد عمليات مسجلة"));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transList.length,
      itemBuilder: (context, index) {
        final t = transList[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: const Color(0xFFF0EDFF), child: Text(_getEmoji(t.category), style: const TextStyle(fontSize: 18))),
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
 Widget _buildSmartComparisonInsight(double currentMonthSpent) {
  return FutureBuilder<double>(
    future: _getLastMonthExpenses(), // دالة جلب بيانات الشهر الماضي
    builder: (context, snapshot) {
      double lastMonthSpent = snapshot.data ?? 0.0;
      
      // إذا لم تكن هناك بيانات للشهر الماضي بعد، لا نعرض شيئاً أو نعرض رسالة ترحيب
      if (lastMonthSpent == 0) return const SizedBox.shrink();

      double difference = lastMonthSpent - currentMonthSpent;
      bool isSaving = difference > 0;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSaving ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSaving ? Colors.green[200]! : Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(isSaving ? Icons.insights : Icons.priority_high, 
                 color: isSaving ? Colors.green : Colors.orange[800]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSaving 
                  ? "أداء رهيب يا حسام! صرفت أقل من الشهر الماضي بـ ${difference.toStringAsFixed(0)} ريال. 🌟" 
                  : "صرفك هذا الشهر زاد بـ ${difference.abs().toStringAsFixed(0)} ريال عن الشهر الماضي. هل نحتاج مراجعة الخطة؟ 🧐",
                style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Future<double> _getLastMonthExpenses() async {
  if (userId == null) return 0.0;

  // تحديد بداية ونهاية الشهر الماضي
  DateTime now = DateTime.now();
  DateTime firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
  DateTime lastDayLastMonth = DateTime(now.year, now.month, 0);

  var snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayLastMonth))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayLastMonth))
      .get();

  double total = 0;
  for (var doc in snapshot.docs) {
    total += (doc.data()['amount'] as num).toDouble();
  }
  return total;
}

void _checkBudgetStatusAndNotify(double currentSpent, double target) async {
  double usageRatio = currentSpent / target;
  String title = "";
  String body = "";

  if (usageRatio >= 1.0) {
    title = "🚨 تجاوزت الميزانية!";
    body = "يا حسام، لقد تخطيت ميزانيتك بمقدار ${(currentSpent - target).toStringAsFixed(0)} ريال.";
  } else if (usageRatio >= 0.8) {
    title = "⚠️ تنبيه الميزانية";
    body = "انتبه، لقد استهلكت 80% من ميزانيتك المحددة.";
  }

  if (title.isNotEmpty) {
    // عرض الإشعار داخل التطبيق
    _showSmartNotification(title, body, usageRatio >= 1.0 ? Colors.red : Colors.orange);
    
    // ملاحظة: لإرسال إشعار حقيقي للخارج (Push) بدون سيرفر
    // نستخدم عادة مكتبة flutter_local_notifications مع هذا الجزء
    print("إرسال تنبيه للنظام: $title - $body");
  }
}

void _showSmartNotification(String title, String message, Color color) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(message, style: GoogleFonts.tajawal(fontSize: 12)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 4),
    ),
  );
}

}