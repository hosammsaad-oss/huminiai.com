import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsStore extends StatelessWidget {
  final int currentPoints;
  const RewardsStore({super.key, required this.currentPoints});

  // قائمة المكافآت (يمكنك تعديل التكلفة هنا)
  final List<Map<String, dynamic>> rewards = const [
    {'id': 'theme', 'title': 'اللون الذهبي للملف', 'cost': 500, 'icon': Icons.palette},
    {'id': 'questions', 'title': '10 أسئلة إضافية', 'cost': 200, 'icon': Icons.auto_awesome},
    {'id': 'ads', 'title': 'إزالة الإعلانات (أسبوع)', 'cost': 1000, 'icon': Icons.block},
  ];

  Future<void> _redeemReward(BuildContext context, String title, int cost) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نقاطك لا تكفي لاستبدال هذه المكافأة')),
      );
      return;
    }

    try {
      // تحديث النقاط في Firestore بالخصم
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(-cost),
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('تم الاستبدال بنجاح!'),
            content: Text('مبروك! حصلت على: $title'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('رائع'))
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في الاتصال')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('متجر المكافآت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // عرض الرصيد في المتجر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.amber.withOpacity(0.1),
              child: Column(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 40),
                  const SizedBox(height: 10),
                  Text('رصيدك المتاح: $currentPoints نقطة', 
                       style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final item = rewards[index];
                  final bool canAfford = currentPoints >= item['cost'];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      leading: Icon(item['icon'], color: const Color(0xFF6B4EFF)),
                      title: Text(item['title'], style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      subtitle: Text('التكلفة: ${item['cost']} نقطة'),
                      trailing: ElevatedButton(
                        onPressed: canAfford ? () => _redeemReward(context, item['title'], item['cost']) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford ? Colors.green : Colors.grey,
                        ),
                        child: const Text('استبدال', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}