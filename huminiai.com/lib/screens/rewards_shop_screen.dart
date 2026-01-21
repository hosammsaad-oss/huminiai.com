import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsShopScreen extends StatelessWidget {
  const RewardsShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("متجر المكافآت 💎", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // --- قسم الرصيد الحالي ---
            _buildBalanceHeader(user?.uid),

            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text("الميزات المتاحة", style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 10),

            // --- قائمة المكافآت ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _rewardItem(
                    context,
                    id: "unlimited_images",
                    title: "تحليل صور غير محدود",
                    desc: "افتح القدرة على تحليل عدد لا نهائي من الصور لمدة 24 ساعة.",
                    cost: 150,
                    icon: Icons.image_search,
                    color: Colors.orange,
                    userId: user?.uid,
                  ),
                  _rewardItem(
                    context,
                    id: "golden_theme",
                    title: "الثيم الذهبي الملكي",
                    desc: "تغيير واجهة التطبيق للون الذهبي الفاخر لتمييز حسابك.",
                    cost: 500,
                    icon: Icons.palette,
                    color: Colors.amber,
                    userId: user?.uid,
                  ),
                  _rewardItem(
                    context,
                    id: "skip_challenge",
                    title: "تخطي التحدي اليومي",
                    desc: "أكمل تحدي اليوم فوراً واحصل على الـ 50 نقطة بدون مجهود.",
                    cost: 100,
                    icon: Icons.fast_forward,
                    color: Colors.blue,
                    userId: user?.uid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت عرض الرصيد
  Widget _buildBalanceHeader(String? userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        int points = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          points = (snapshot.data!.data() as Map<String, dynamic>)['points'] ?? 0;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 50),
              const SizedBox(height: 10),
              Text("رصيدك الحالي", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 16)),
              Text("$points نقطة", style: GoogleFonts.poppins(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // ويدجت عنصر المكافأة
  Widget _rewardItem(BuildContext context, {
    required String id,
    required String title,
    required String desc,
    required int cost,
    required IconData icon,
    required Color color,
    required String? userId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _purchaseReward(context, userId, id, cost),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("$cost ن"),
          ),
        ],
      ),
    );
  }

  // منطق الشراء
  void _purchaseReward(BuildContext context, String? userId, String rewardId, int cost) async {
    if (userId == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        int currentPoints = snapshot.get('points') ?? 0;

        if (currentPoints >= cost) {
          transaction.update(userDoc, {'points': currentPoints - cost});
          // هنا يمكن إضافة الوظيفة المشتراة في مجموعة فرعية تسمى 'purchases'
          transaction.set(userDoc.collection('purchases').doc(rewardId), {
            'purchaseDate': FieldValue.serverTimestamp(),
            'active': true,
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم الشراء بنجاح! استمتع بميزتك الجديدة 🥳")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("عذراً، لا تملك نقاطاً كافية 😅")),
          );
        }
      });
    } catch (e) {
      print("Purchase Error: $e");
    }
  }
}