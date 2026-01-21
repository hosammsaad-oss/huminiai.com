import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/points_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LuckyChestScreen extends StatefulWidget {
  const LuckyChestScreen({super.key});

  @override
  State<LuckyChestScreen> createState() => _LuckyChestScreenState();
}

class _LuckyChestScreenState extends State<LuckyChestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpening = false;
  String _rewardMessage = "";
  final int _chestCost = 50; // تكلفة فتح الصندوق

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _openChest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // جلب نقاط المستخدم للتأكد
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    int currentPoints = userDoc.data()?['points'] ?? 0;

    if (currentPoints < _chestCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("نقاطك لا تكفي لفتح الصندوق! 😢")),
      );
      return;
    }

    setState(() {
      _isOpening = true;
      _rewardMessage = "";
    });

    // خصم النقاط
    await PointsService.addPoints(-_chestCost);

    // اختيار جائزة عشوائية
    _controller.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 2));
    _controller.stop();

    final rewards = [
      {"msg": "ربحت 100 نقطة إضافية! 💰", "points": 100},
      {"msg": "وسام 'المستكشف الشجاع' 🎖️", "points": 10},
      {"msg": "حظ أوفر المرة القادمة! 🍀", "points": 0},
      {"msg": "ربحت 200 نقطة! ملك الحظ 👑", "points": 200},
    ];

    final win = rewards[Random().nextInt(rewards.length)];
    if (win['points'] as int > 0) {
      await PointsService.addPoints(win['points'] as int);
    }

    setState(() {
      _isOpening = false;
      _rewardMessage = win['msg'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("صندوق المفاجآت", style: GoogleFonts.tajawal())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("تكلفة الفتح: $_chestCost نقطة", style: GoogleFonts.tajawal(fontSize: 18)),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _isOpening ? _controller.value * 0.2 : 0,
                  child: Icon(
                    _isOpening ? Icons.gif_box : Icons.redeem,
                    size: 150,
                    color: Colors.amber,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            if (_rewardMessage.isNotEmpty)
              Text(_rewardMessage, 
                style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isOpening ? null : _openChest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_isOpening ? "جاري الفتح..." : "افتح الصندوق 🎁", 
                style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}