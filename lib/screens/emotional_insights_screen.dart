import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmotionalInsightsScreen extends StatelessWidget {
  const EmotionalInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("تحليل المشاعر الأسبوعي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final lastMood = data?['currentMood'] ?? "طبيعي"; // نفترض أنك تخزن المزاج هنا
          final energy = data?['energyLevel'] ?? 50;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoodCard(lastMood, energy),
                const SizedBox(height: 30),
                Text("توصية هوميني الذكية 🦄", style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildAITipCard(lastMood),
                const SizedBox(height: 30),
                _buildWeeklyStatCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodCard(String mood, int energy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF9D8BFF)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text("حالتك الآن", style: GoogleFonts.tajawal(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(mood, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: energy / 100,
            backgroundColor: Colors.white24,
            color: Colors.amber,
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text("مستوى الطاقة: $energy%", style: GoogleFonts.tajawal(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAITipCard(String mood) {
    String tip = "استمر في إنجاز أهدافك، أنت تبلي بلاءً حسناً!";
    if (mood.contains("مضغوط")) tip = "يبدو أنك مررت بأسبوع حافل. خذ 10 دقائق من التأمل الآن، نقاطك لن تذهب بعيداً.";
    if (mood.contains("سعيد")) tip = "هذا هو الوقت المثالي لمهاجمة أهدافك الكبيرة في 'جول سكرين'!";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Text(tip, style: GoogleFonts.tajawal(fontSize: 16, height: 1.5)),
    );
  }

  Widget _buildWeeklyStatCard() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text("رسم بياني للمشاعر (قريباً)", style: GoogleFonts.tajawal(color: Colors.grey))),
    );
  }
}