import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import '../providers/goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  // تعريف userId كـ getter للحصول على المستخدم الحالي بأمان
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: Text("الأهداف الإستراتيجية", 
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4EFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: goals.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (context, index) => _buildGoalCard(context, ref, goals[index]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B4EFF),
        onPressed: () => _showAddGoalDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // دالة الحفظ في Firestore - وضعناها داخل الكلاس لتعرف userId
  Future<void> _setSavingsGoalInFirestore(String title, double targetAmount) async {
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc('primary_goal')
          .set({
        'title': title,
        'target': targetAmount,
        'current_saved': 0.0,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving goal: $e");
    }
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(goal.title, style: GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                onPressed: () => ref.read(goalsProvider.notifier).deleteGoal(goal.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF6B4EFF),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text("${(goal.progress * 100).toInt()}%", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4EFF))),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildProgressButton(Icons.remove, () {
                ref.read(goalsProvider.notifier).updateGoalProgress(goal.id, (goal.progress - 0.1).clamp(0.0, 1.0));
              }),
              const SizedBox(width: 20),
              _buildProgressButton(Icons.add, () {
                ref.read(goalsProvider.notifier).updateGoalProgress(goal.id, (goal.progress + 0.1).clamp(0.0, 1.0));
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF6B4EFF)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          Text("لا توجد أهداف إستراتيجية بعد", style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController(); // لإضافة المبلغ المستهدف

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("إضافة هدف إستراتيجي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(hintText: "مثلاً: شراء سيارة")),
              const SizedBox(height: 10),
              TextField(
                controller: amountController, 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "المبلغ المستهدف (ريال)"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF)),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  // 1. تحديث الـ Provider المحلي (Riverpod)
                  ref.read(goalsProvider.notifier).addGoal(titleController.text);
                  
                  // 2. الحفظ في السحابة (Firestore)
                  double target = double.tryParse(amountController.text) ?? 0.0;
                  await _setSavingsGoalInFirestore(titleController.text, target);
                  
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("إضافة", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}