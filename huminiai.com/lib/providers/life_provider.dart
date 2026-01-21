import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskModel {
  final String id;
  final String title;
  final bool isCompleted;
  final String category;
  final String hqiCategory;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.category = 'daily',
    this.hqiCategory = 'التزام',
  });
}

class LifeNotifier extends StateNotifier<List<TaskModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LifeNotifier() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel(
          id: doc.id,
          title: data['title'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          category: data['category'] ?? 'daily',
          hqiCategory: data['hqiCategory'] ?? 'التزام',
        );
      }).toList();
    });
  }

  // دالة التقرير الذكي
  String generateWeeklyReport() {
    if (state.isEmpty) return "ابدأ بإضافة مهامك اليوم لكي أحلل أداءك!";
    
    Map<String, int> stats = {
      'التزام': state.where((t) => t.hqiCategory == 'التزام' && t.isCompleted).length,
      'سرعة': state.where((t) => t.hqiCategory == 'سرعة' && t.isCompleted).length,
      'تواصل': state.where((t) => t.hqiCategory == 'تواصل' && t.isCompleted).length,
      'تطور': state.where((t) => t.hqiCategory == 'تطور' && t.isCompleted).length,
      'دقة': state.where((t) => t.hqiCategory == 'دقة' && t.isCompleted).length,
    };

    var sortedKeys = stats.keys.toList()..sort((a, b) => stats[b]!.compareTo(stats[a]!));
    String topCategory = sortedKeys.first;
    String lowCategory = sortedKeys.last;

    if (stats[topCategory] == 0) return "لم تكتمل أي مهام بعد، بانتظار إنجازك الأول! 🔥";

    return "أنت اليوم متميز في '$topCategory' 🌟. أداؤك رائع ولكن لاحظت أن مؤشر '$lowCategory' يحتاج لبعض الاهتمام. ركز عليه غداً لتوازن رادارك!";
  }

  // --- الحل: إضافة دالة الرتبة داخل الكلاس لتتمكن من رؤية _firestore و _auth ---
  Stream<String> watchUserRank() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value("مبتدئ 🌱");

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      final totalXP = data?['totalXP'] ?? 0;

      if (totalXP >= 2000) return "أسطورة الإنجاز 🔥";
      if (totalXP >= 1000) return "قائد ملهم 👑";
      if (totalXP >= 500) return "محترف متطور ⭐";
      if (totalXP >= 200) return "مجتهد نشيط 🚀";
      return "مبتدئ طموح 🌱";
    });
  }

  Future<void> addTask(String title, {String category = 'daily', String hqiCategory = 'التزام'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .add({
      'title': title,
      'isCompleted': false,
      'category': category,
      'hqiCategory': hqiCategory,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});

    int xpChange = !currentStatus ? 50 : -50;

    await _firestore.collection('users').doc(user.uid).set({
      'totalXP': FieldValue.increment(xpChange),
      'lastUpdate': FieldValue.serverTimestamp(),
      'sparkPoints': FieldValue.increment(xpChange),
    }, SetOptions(merge: true));
  }

  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<int> watchUserXP() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.data()?['totalXP'] ?? 0);
  }
}

// --- Providers الخارجة ---

final lifeProvider = StateNotifierProvider<LifeNotifier, List<TaskModel>>((ref) => LifeNotifier());

final userXPProvider = StreamProvider<int>((ref) {
  return ref.watch(lifeProvider.notifier).watchUserXP();
});

// تعديل استدعاء الرتبة هنا ليستخدم watchUserRank من داخل النوتيفاير
final userRankProvider = StreamProvider<String>((ref) {
  return ref.watch(lifeProvider.notifier).watchUserRank();
});