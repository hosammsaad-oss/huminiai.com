import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. الموديل المحدث مع إضافة الحقول المطلوبة
class TaskModel {
  final String id;
  final String title;
  final bool isCompleted;
  final String category; // تم إضافة حقل التصنيف

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false, // تم إضافة الفاصلة هنا لإصلاح الخطأ
    this.category = 'daily', // القيمة الافتراضية يومية
  });

  get hqiCategory => null;
}

class LifeNotifier extends StateNotifier<List<TaskModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int currentUserXP = 0;

  LifeNotifier() : super([]) {
    _loadTasks();
  }
  String generateWeeklyReport() {
    final tasks = state;
    if (tasks.isEmpty) return "ابدأ بإضافة مهامك لكي يحلل هيوميني أداءك! ✨";

    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();

    if (completedTasks.isEmpty) return "بانتظار إنجازك الأول اليوم! 🔥";

    // 1. تحليل الفئات الأكثر إنجازاً
    Map<String, int> counts = {};
    for (var task in completedTasks) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    var topCategory = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 2. تحليل التعثر (المهام غير المكتملة)
    String struggleAdvice = "";
    if (pendingTasks.isNotEmpty) {
      Map<String, int> pendingCounts = {};
      for (var task in pendingTasks) {
        pendingCounts[task.category] = (pendingCounts[task.category] ?? 0) + 1;
      }
      var struggleCategory = pendingCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // تقديم نصيحة مخصصة بناءً على فئة التعثر
      switch (struggleCategory) {
        case 'تطور':
          struggleAdvice =
              "لاحظت تعثراً في جانب التطور، جرب تخصيص 10 دقائق فقط للقراءة الآن.";
          break;
        case 'سرعة':
          struggleAdvice =
              "مهام السرعة متراكمة، ابدأ بأصغر مهمة لكسر حاجز التأجيل.";
          break;
        case 'التزام':
          struggleAdvice =
              "الانضباط يحتاج طاقة، تأكد من أخذ قسط من الراحة لتستعيد تركيزك.";
          break;
        default:
          struggleAdvice =
              "لديك مهام معلقة، إنهاء واحدة منها الآن سيحفز هرمون الإنجاز لديك!";
      }
    }

    String generateWeeklyReport() {
      final tasks = state;
      if (tasks.isEmpty) return "ابدأ بإضافة مهامك لكي يحلل هيوميني أداءك! ✨";

      final completedTasks = tasks.where((t) => t.isCompleted).toList();
      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();

      if (completedTasks.isEmpty) return "بانتظار إنجازك الأول اليوم! 🔥";

      // 1. تحليل الفئات الأكثر إنجازاً
      Map<String, int> counts = {};
      for (var task in completedTasks) {
        counts[task.category] = (counts[task.category] ?? 0) + 1;
      }
      var topCategory = counts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // 2. تحليل التعثر (المهام غير المكتملة)
      String struggleAdvice = "";
      if (pendingTasks.isNotEmpty) {
        Map<String, int> pendingCounts = {};
        for (var task in pendingTasks) {
          pendingCounts[task.category] =
              (pendingCounts[task.category] ?? 0) + 1;
        }
        var struggleCategory = pendingCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        // تقديم نصيحة مخصصة بناءً على فئة التعثر
        switch (struggleCategory) {
          case 'تطور':
            struggleAdvice =
                "لاحظت تعثراً في جانب التطور، جرب تخصيص 10 دقائق فقط للقراءة الآن.";
            break;
          case 'سرعة':
            struggleAdvice =
                "مهام السرعة متراكمة، ابدأ بأصغر مهمة لكسر حاجز التأجيل.";
            break;
          case 'التزام':
            struggleAdvice =
                "الانضباط يحتاج طاقة، تأكد من أخذ قسط من الراحة لتستعيد تركيزك.";
            break;
          default:
            struggleAdvice =
                "لديك مهام معلقة، إنهاء واحدة منها الآن سيحفز هرمون الإنجاز لديك!";
        }
      }

      return "أنت متميز اليوم في جانب ($topCategory)! 🌟. $struggleAdvice";
    }

    return "أنت متميز اليوم في جانب ($topCategory)! 🌟. $struggleAdvice";
  }

  // 2. تحديث قراءة البيانات لتشمل الـ category
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
              category:
                  data['category'] ?? 'daily', // قراءة التصنيف من Firestore
            );
          }).toList();
        });
  }

  // 3. تحديث دالة الإضافة لتخزين التصنيف (يومي/أسبوعي/شهري)
  Future<void> addTask(String title, {String category = 'daily'}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('tasks').add({
      'title': title,
      'isCompleted': false,
      'category': category, // تخزين التصنيف في Firestore
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // دالة toggleTask كما هي لإدارة نقاط البريق
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

final lifeProvider = StateNotifierProvider<LifeNotifier, List<TaskModel>>(
  (ref) => LifeNotifier(),
);

final userXPProvider = StreamProvider<int>((ref) {
  return ref.watch(lifeProvider.notifier).watchUserXP();
});

final userRankProvider = FutureProvider<String>((ref) async {
  final tasks = ref.watch(lifeProvider);
  int completed = tasks.where((t) => t.isCompleted).length;
  if (completed > 10) return "بطل خارق ⚡";
  if (completed > 5) return "منجز محترف 🔥";
  return "مبتدئ طموح 🌱";
});
