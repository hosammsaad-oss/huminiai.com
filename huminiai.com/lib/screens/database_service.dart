import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // جلب المعرف الخاص بالمستخدم الحالي
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // 1. حفظ هدف التوفير (جعلناها عامة بحذف الشرطة السفلية)
  Future<void> setSavingsGoal(String title, double targetAmount) async {
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc('primary_goal')
        .set({
      'title': title,
      'target': targetAmount,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // 2. جلب الهدف الحالي لمتابعته في الواجهة
  Stream<DocumentSnapshot> getPrimaryGoal() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc('primary_goal')
        .snapshots();
  }

  // 3. حفظ عملية شراء جديدة في Firestore
  Future<void> addTransaction(String label, double amount, String category) async {
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('transactions').add({
      'label': label,
      'amount': amount,
      'category': category,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // 4. جلب العمليات على شكل Stream (تحديث تلقائي)
  Stream<QuerySnapshot> getTransactions() {
    if (userId == null) return const Stream.empty();
    
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }
}