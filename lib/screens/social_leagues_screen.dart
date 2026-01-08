import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialLeaguesScreen extends StatelessWidget {
  const SocialLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("ساحة المنافسة 🏆", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // --- 1. قسم تحدي اليوم الذكي ---
            _buildDailyChallengeCard(),

            const SizedBox(height: 10),
            
            // --- العنوان ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text("متصدري هوميني", style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("Top 20", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- 2. لوحة الصدارة الحية (Real-time Leaderboard) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('points', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("لا توجد منافسات حالياً، كن الأول!", style: GoogleFonts.tajawal()),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final userData = docs[index].data() as Map<String, dynamic>;
                      final isMe = docs[index].id == currentUser?.uid;

                      return _buildLeaderboardTile(
                        rank: index + 1,
                        name: userData['displayName'] ?? "مستخدم هيومني",
                        points: userData['points'] ?? 0,
                        isMe: isMe,
                        photoUrl: userData['photoUrl'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ويلجت تحدي اليوم (تصميمك الأصلي مع لمسات تحسينية) ---
  Widget _buildDailyChallengeCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF00D2FF)], // تم دمج التدرج اللوني الجديد
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("تحدي اليوم ⚡", 
                style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: const Text("متبقي 5 ساعات", 
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "أكمل 3 محادثات مع الذكاء الاصطناعي حول أهدافك اليومية لتحصل على المكافأة.",
            style: GoogleFonts.tajawal(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 15),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6, 
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2), 
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("المكافأة: +50 نقطة 🦄", 
                style: GoogleFonts.tajawal(color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("60%", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  // --- ويلجت سطر المتصدرين (تم دمج منطق الرتب والألوان) ---
  Widget _buildLeaderboardTile({
    required int rank, 
    required String name, 
    required int points, 
    required bool isMe, 
    String? photoUrl
  }) {
    // تحديد لون الرتبة للمراكز الثلاثة الأولى
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber; // ذهبي
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // فضي
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // برونزي
    } else {
      rankColor = Colors.grey.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6B4EFF).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isMe ? Border.all(color: const Color(0xFF6B4EFF), width: 1.5) : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          if (isMe) BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // رقم الترتيب أو أيقونة الكأس
          SizedBox(
            width: 35,
            child: rank <= 3 
              ? Icon(Icons.emoji_events, color: rankColor, size: 24)
              : Text("#$rank", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(width: 10),
          // الصورة الشخصية
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null 
              ? Text(name.substring(0, 1), style: const TextStyle(color: Color(0xFF6B4EFF))) 
              : null,
          ),
          const SizedBox(width: 15),
          // الاسم (مع علامة "أنت")
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: isMe ? const Color(0xFF6B4EFF) : Colors.black87
                  )
                ),
                if (isMe) Text("أنت الآن في المنافسة!", style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          // النقاط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$points ن", 
              style: GoogleFonts.poppins(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 14)
            ),
          ),
        ],
      ),
    );
  }
}