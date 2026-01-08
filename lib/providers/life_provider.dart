import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



// الموديل كما هو لضمان توافق HomeScreen
class TaskModel {
  final String id;
  final String title;
  final bool isCompleted;

  TaskModel({
    required this.id, 
    required this.title, 
    this.isCompleted = false
  });
}

class LifeNotifier extends StateNotifier<List<TaskModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إضافة متابعة النقاط محلياً (إلى جانب Firestore)
  int currentUserXP = 0;

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
        );
      }).toList();
    });
  }

  // إضافة مهمة جديدة - كما هي تماماً
  Future<void> addTask(String title) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .add({
      'title': title,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // تعديل دالة toggleTask لإدارة نقاط البريق (Spark Points) بشكل كامل
  Future<void> toggleTask(String taskId, bool currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // 1. تحديث حالة المهمة في Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});

    // 2. نظام النقاط (المكافآت):
    // إذا أصبحت المهمة مكتملة (!currentStatus == true) نمنح 50 نقطة
    // إذا ألغى المستخدم الإكمال نعيد سحب النقاط
    int xpChange = !currentStatus ? 50 : -50;

    await _firestore.collection('users').doc(user.uid).set({
      'totalXP': FieldValue.increment(xpChange),
      'lastUpdate': FieldValue.serverTimestamp(),
      'sparkPoints': FieldValue.increment(xpChange), // نقاط البريق الإضافية
    }, SetOptions(merge: true));
  }

  // حذف مهمة (لضمان كمالية الملف)
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

  // دالة لمراقبة النقاط بشكل مباشر في أي مكان في التطبيق
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

// تعريف البروفايدر الأساسي
final lifeProvider = StateNotifierProvider<LifeNotifier, List<TaskModel>>((ref) => LifeNotifier());

// --- هذا هو الجزء الذي يحل مشكلة الـ Undefined name في ملف الشاشة ---
// بروفايدر إضافي لمراقبة النقاط فقط وتحديث الواجهة فوراً
final userXPProvider = StreamProvider<int>((ref) {
  return ref.watch(lifeProvider.notifier).watchUserXP();
});