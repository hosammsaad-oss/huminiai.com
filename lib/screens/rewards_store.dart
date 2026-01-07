import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsStore extends StatelessWidget {
  final int currentPoints;
  
  // حل مشكلة الـ const: قمت بإزالة كلمة const من هنا
  final List<Map<String, dynamic>> rewards = [
    {
      'id': 'theme_gold',
      'title': 'السمة الذهبية للملف',
      'cost': 500,
      'icon': Icons.palette_outlined,
      'color': Colors.amber
    },
    {
      'id': 'extra_questions',
      'title': '10 أسئلة ذكاء إضافية',
      'cost': 200,
      'icon': Icons.bolt,
      'color': Colors.blue
    },
    {
      'id': 'no_ads',
      'title': 'إزالة الإعلانات (أسبوع)',
      'cost': 1000,
      // حل مشكلة الأيقونة: تم تغيير ad_units_off إلى mobile_off لأنها أكثر توافقاً
      'icon': Icons.mobile_off, 
      'color': Colors.redAccent
    },
  ];

  // حل مشكلة الـ constructor: أزلنا كلمة const من هنا أيضاً
  RewardsStore({super.key, required this.currentPoints});

  Future<void> _redeemReward(BuildContext context, String title, int cost) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، نقاطك لا تكفي لهذه المكافأة')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(-cost),
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تمت العملية بنجاح! 🎉', textAlign: TextAlign.center),
            content: Text('لقد حصلت على: $title \n تم خصم $cost نقطة من رصيدك.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('رائع'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الاتصال بالخادم')),
        );
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
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 50),
                  const SizedBox(height: 10),
                  Text('رصيدك المتاح حالياً', style: GoogleFonts.tajawal(fontSize: 14)),
                  Text(
                    '$currentPoints نقطة',
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF6B4EFF)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final item = rewards[index];
                  final bool canAfford = currentPoints >= item['cost'];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: (item['color'] as Color).withOpacity(0.1),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                      ),
                      title: Text(item['title'], style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      subtitle: Text('التكلفة: ${item['cost']} نقطة', style: GoogleFonts.poppins()),
                      trailing: ElevatedButton(
                        onPressed: canAfford ? () => _redeemReward(context, item['title'], item['cost']) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford ? Colors.green : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('استبدال'),
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