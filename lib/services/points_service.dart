import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> addPoints(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // نستخدم set مع merge لضمان إنشاء الحقل إذا لم يكن موجوداً
      await userDoc.set({
        'points': FieldValue.increment(amount),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("✅ تم إضافة $amount نقطة بنجاح");
    } catch (e) {
      // طباعة الخطأ في الـ Console لتعرف إذا كانت المشكلة في الصلاحيات
      print("❌ فشل إضافة النقاط: $e");
    }
  }
}