import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تأكد من وجود هذا الملف في مشروعك
import '../services/points_service.dart';

class Goal {
  final String id;
  final String title;
  final double progress;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.progress,
    required this.createdAt,
  });
}

class GoalsNotifier extends StateNotifier<List<Goal>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoalsNotifier() : super([]) {
    _loadGoals();
  }

  void _loadGoals() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          state = snapshot.docs.map((doc) {
            final data = doc.data();
            return Goal(
              id: doc.id,
              title: data['title'] ?? '',
              progress: (data['progress'] ?? 0.0).toDouble(),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  Future<void> addGoal(String title) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('goals').add({
      'title': title,
      'progress': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ميزة اليونيكورن: مكافأة 5 نقاط بمجرد كتابة هدف جديد للتشجيع على التخطيط
    await PointsService.addPoints(5);
  }

  Future<void> deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  Future<void> updateGoalProgress(String goalId, double newProgress) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc(goalId)
        .update({'progress': newProgress});

    // ميزة اليونيكورن: إذا وصل التقدم إلى 100% (قيمة 1.0)، امنح المستخدم 20 نقطة
    if (newProgress >= 1.0) {
      await PointsService.addPoints(20);
    }
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>(
  (ref) => GoalsNotifier(),
);
