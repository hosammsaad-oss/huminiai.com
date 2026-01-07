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
        title: Text("ساحة المنافسة", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // --- قسم تحدي اليوم ---
            _buildDailyChallengeCard(),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text("متصدري الأسبوع", style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- لوحة الصدارة (Leaderboard) ---
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
                    return const Center(child: Text("لا توجد بيانات حالياً"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
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

  // ويلجت تحدي اليوم
  Widget _buildDailyChallengeCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF9D8BFF)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("تحدي اليوم ⚡", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text("متبقي 5 ساعات", style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text("أكمل 3 محادثات مع الذكاء الاصطناعي حول أهدافك اليومية.", style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: 0.6, backgroundColor: Colors.white.withOpacity(0.3), color: Colors.amber),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("المكافأة: +50 نقطة", style: GoogleFonts.tajawal(color: Colors.amber, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ويلجت سطر المتصدرين
  Widget _buildLeaderboardTile({required int rank, required String name, required int points, required bool isMe, String? photoUrl}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6B4EFF).withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: isMe ? Border.all(color: const Color(0xFF6B4EFF)) : null,
      ),
      child: Row(
        children: [
          Text("#$rank", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: rank <= 3 ? Colors.amber : Colors.grey)),
          const SizedBox(width: 15),
          CircleAvatar(
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(name, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16))),
          Text("$points ن", style: GoogleFonts.poppins(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}