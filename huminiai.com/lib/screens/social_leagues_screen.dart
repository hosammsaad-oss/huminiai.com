import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart'; // استيراد المكتبة
import 'rewards_shop_screen.dart'; 

class SocialLeaguesScreen extends StatefulWidget {
  const SocialLeaguesScreen({super.key});

  @override
  State<SocialLeaguesScreen> createState() => _SocialLeaguesScreenState();
}

class _SocialLeaguesScreenState extends State<SocialLeaguesScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playWelcomeSound(); // تشغيل الصوت عند الدخول
  }

  void _playWelcomeSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/level_up.mp3'));
    } catch (e) {
      print("خطأ في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // تنظيف الموارد
    super.dispose();
  }

  Map<String, dynamic> _getUserTitle(int points) {
    if (points >= 1000) return {'title': 'أسطورة هوميني 👑', 'color': Colors.purple};
    if (points >= 500) return {'title': 'خبير الأهداف 🧠', 'color': Colors.blue};
    if (points >= 100) return {'title': 'مكافح نشط 🔥', 'color': Colors.orange};
    return {'title': 'مبتدئ هوميني 🌱', 'color': Colors.green};
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("ساحة المنافسة 🏆", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsShopScreen()));
            },
            icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B4EFF), size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildDailyChallengeCard(currentUser?.uid),
            _buildMyRankStatus(currentUser?.uid),
            const SizedBox(height: 10),
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
                    return Center(child: Text("لا توجد منافسات حالياً", style: GoogleFonts.tajawal()));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final userData = docs[index].data() as Map<String, dynamic>;
                      final isMe = docs[index].id == currentUser?.uid;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                        ),
                        child: _buildLeaderboardTile(
                          rank: index + 1,
                          name: userData['displayName'] ?? "مستخدم هيومني",
                          points: userData['points'] ?? 0,
                          isMe: isMe,
                          photoUrl: userData['photoUrl'],
                        ),
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

  // --- دوال الـ Widgets (بقيت كما هي مع تعديل بسيط لتصبح داخل الـ State) ---
  Widget _buildMyRankStatus(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('points', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        final myIndex = docs.indexWhere((doc) => doc.id == userId);
        if (myIndex == -1) return const SizedBox();
        final myRank = myIndex + 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4EFF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFF6B4EFF), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  myRank <= 3 ? "مذهل! أنت ضمن الثلاثة الأوائل 🔥" : "ترتيبك الحالي هو #$myRank. استمر في التقدم!",
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyChallengeCard(String? userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        int chatCount = 0;
        bool isCompleted = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String today = DateTime.now().toIso8601String().split('T')[0];
          if (data['lastChallengeDate'] == today) {
            chatCount = data['dailyChatCount'] ?? 0;
            isCompleted = data['challengeCompleted'] ?? false;
          }
        }
        double progressValue = (chatCount / 3).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF00D2FF)]),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تحدي اليوم ⚡", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(isCompleted ? "مكتمل ✅" : "متبقي ${3 - chatCount} محادثات", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: progressValue, backgroundColor: Colors.white24, color: Colors.amber),
              const SizedBox(height: 10),
              Text(isCompleted ? "تم استلام المكافأة 🎉" : "المكافأة: +50 نقطة 🦄", style: GoogleFonts.tajawal(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTile({required int rank, required String name, required int points, required bool isMe, String? photoUrl}) {
    final titleData = _getUserTitle(points);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6B4EFF).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isMe ? const Color(0xFF6B4EFF) : Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          SizedBox(width: 35, child: rank <= 3 ? const Icon(Icons.emoji_events, color: Colors.amber) : Text("#$rank")),
          CircleAvatar(backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null, child: photoUrl == null ? Text(name[0]) : null),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                Text(titleData['title'], style: TextStyle(color: titleData['color'], fontSize: 11)),
              ],
            ),
          ),
          Text("$points ن", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4EFF))),
        ],
      ),
    );
  }
}