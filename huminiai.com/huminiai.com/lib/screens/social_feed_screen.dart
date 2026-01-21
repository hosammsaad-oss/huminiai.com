import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SocialFeedScreen extends ConsumerWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // خلفية فاتحة ومريحة
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "مجتمع المنجزين ✨",
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4EFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: Colors.amber),
            onPressed: () {
              // يمكن إضافة صفحة المتصدرين هنا لاحقاً
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4EFF)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final posts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _buildPostCard(context, post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6B4EFF),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          "شارك إنجازك",
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _showCreatePostDialog(context),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final DateTime? date = (post['timestamp'] as Timestamp?)?.toDate();
    final String timeAgo = date != null ? DateFormat('jm').format(date) : "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
              child: Text(
                (post['authorName'] ?? "M")[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              post['authorName'] ?? "منجز مجهول",
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(timeAgo, style: const TextStyle(fontSize: 10)),
            trailing: const Icon(Icons.more_vert, size: 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post['content'] ?? "",
              style: GoogleFonts.tajawal(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.grey[100]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionBtn(
                  Icons.local_fire_department_rounded,
                  "عاش",
                  Colors.orange,
                ),
                _buildActionBtn(Icons.auto_awesome, "ملهم", Colors.amber),
                _buildActionBtn(
                  Icons.chat_bubble_outline_rounded,
                  "تعليق",
                  Colors.blueGrey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {}, // سيتم إضافة منطق التفاعل لاحقاً
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style: GoogleFonts.tajawal(fontSize: 13, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "كن أول من ينشر إنجازه اليوم! ✨",
            style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final TextEditingController postController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "بصمة نجاح جديدة 🚀",
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: postController,
                maxLines: 5,
                autofocus: true,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  hintText: "ما هو التحدي الذي اجتزته؟ هوميني فخور بك...",
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    if (postController.text.trim().isNotEmpty) {
                      await _savePostToFirestore(postController.text);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "نشر في المجتمع ✨",
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePostToFirestore(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user?.uid ?? 'guest',
      'authorName': user?.displayName ?? 'منجز متخفي',
      'content': content,
      'type': 'achievement',
      'timestamp': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'reactions': [],
    });
  }
}
