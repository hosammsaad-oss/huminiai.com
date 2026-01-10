import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsStore extends StatelessWidget {
  final int currentPoints;
  const RewardsStore({super.key, required this.currentPoints});

  final List<Map<String, dynamic>> rewards = const [
    {'id': 'theme', 'title': 'اللون الذهبي للملف', 'cost': 500, 'icon': Icons.palette, 'desc': 'اجعل ملفك الشخصي يتلألأ باللون الملكي'},
    {'id': 'questions', 'title': '10 أسئلة إضافية', 'cost': 200, 'icon': Icons.auto_awesome, 'desc': 'زد فرصك في التعلم والحصول على نقاط'},
    {'id': 'ads', 'title': 'إزالة الإعلانات', 'cost': 1000, 'icon': Icons.block, 'desc': 'تصفح التطبيق بدون أي إزعاج لمدة أسبوع'},
  ];

  Future<void> _redeemReward(BuildContext context, Map<String, dynamic> reward) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // تأكيد الشراء أولاً (نظام حماية للمستخدم)
    bool confirm = await _showConfirmDialog(context, reward['title'], reward['cost']);
    if (!confirm) return;

    try {
      // 1. تحديث النقاط و 2. تسجيل المكافأة في "حقيبة" المستخدم
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'points': FieldValue.increment(-reward['cost']),
        'inventory': FieldValue.arrayUnion([reward['id']]), // إضافة المكافأة للمخزون
        'lastTransaction': DateTime.now(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        _showSuccessAnimation(context, reward['title']);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء المعالجة')));
      }
    }
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, int cost) async {
    return await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الاستبدال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Text('هل تريد استبدال $cost نقطة مقابل $title؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  void _showSuccessAnimation(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text('تهانينا!', style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            Text('تم تفعيل $title بنجاح', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للمتجر'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('متجر المكافآت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // بطاقة الرصيد الذكية
            _buildBalanceCard(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text("نصيحة ذكية: اجمع النقاط من خلال إكمال المهام اليومية!", 
                       style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final item = rewards[index];
                  final double progress = (currentPoints / item['cost']).clamp(0.0, 1.0);
                  final bool canAfford = currentPoints >= item['cost'];

                  return _buildRewardItem(context, item, progress, canAfford);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF9D8BFF)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رصيدك الحالي', style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text('$currentPoints', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 5),
                  Text('نقطة', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 16)),
                ],
              ),
            ],
          ),
          const Icon(Icons.shopping_basket_outlined, color: Colors.white24, size: 60),
        ],
      ),
    );
  }

  Widget _buildRewardItem(BuildContext context, Map<String, dynamic> item, double progress, bool canAfford) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: canAfford ? const Color(0xFF6B4EFF).withOpacity(0.3) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF6B4EFF).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(item['icon'], color: const Color(0xFF6B4EFF)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['desc'], style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${item['cost']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber[800])),
                    const Text('نقطة', style: TextStyle(fontSize: 10)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            // شريط التقدم نحو المكافأة
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(canAfford ? Colors.green : const Color(0xFF6B4EFF)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(canAfford ? "جاهز للاستبدال!" : "يتبقى لك ${item['cost'] - currentPoints} نقطة", 
                     style: GoogleFonts.tajawal(fontSize: 11, color: canAfford ? Colors.green : Colors.grey)),
                ElevatedButton(
                  onPressed: canAfford ? () => _redeemReward(context, item) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('استبدال الآن', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}