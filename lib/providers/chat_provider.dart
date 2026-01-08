import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

// استيراد الموديلات والخدمات
import 'life_provider.dart';
import 'goals_provider.dart';
import '../services/context_service.dart';
import '../services/points_service.dart'; // استيراد خدمة النقاط

class ChatMessage {
  final String text;
  final bool isUser;
  final String? base64Image;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, this.base64Image, required this.timestamp});

  Map<String, dynamic> toMap(String userId) {
    return {
      'text': text,
      'isUser': isUser,
      'base64Image': base64Image,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
    };
  }
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? _cachedUserId;

  final _geminiModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyDpKkg_1-o5jE9Hmy8Ei_H_6hcWNgB8-IQ', 
  );

  ChatNotifier(this.ref) : super([]) { _initAndLoadMessages(); }

  Future<String> _getOrCreateUserId() async {
    if (_auth.currentUser != null) return _auth.currentUser!.uid;
    if (_cachedUserId != null) return _cachedUserId!;
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('humini_user_id');
    if (storedId == null) {
      storedId = const Uuid().v4();
      await prefs.setString('humini_user_id', storedId);
    }
    _cachedUserId = storedId;
    return storedId;
  }

  void _initAndLoadMessages() async {
    final userId = await _getOrCreateUserId();
    _firestore.collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: false)
        .snapshots().listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          text: data['text'] ?? "",
          isUser: data['isUser'] ?? true,
          base64Image: data['base64Image'],
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> pickAndSendImage(List<TaskModel> tasks, List<Goal> goals) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await sendMessage("حلل هذه الصورة بناءً على سياق مهامي وأهدافي", imageBytes: bytes);
  }

  Future<String> _askGemini(String text, String? base64Image) async {
    try {
      final List<Part> parts = [TextPart(text)];
      if (base64Image != null) {
        final bytes = base64Decode(base64Image.contains(',') ? base64Image.split(',').last : base64Image);
        parts.add(DataPart('image/jpeg', bytes));
      }
      final response = await _geminiModel.generateContent([Content.multi(parts)]);
      return response.text ?? "تم تحليل الصورة بنجاح.";
    } catch (e) { return "عذراً، حدث خطأ في تحليل الصورة: $e"; }
  }

  String _getMoodTranslation(UserMood mood) {
    switch (mood) {
      case UserMood.happy: return "سعيد ومبتهج";
      case UserMood.stressed: return "مضغوط ومتوتر";
      case UserMood.focused: return "مركز جداً";
      case UserMood.tired: return "متعب ومرهق";
      case UserMood.neutral: return "طبيعي";
    }
  }

  Future<void> sendSmartMessage(String userText, List<TaskModel> tasks, List<Goal> goals) async {
    if (userText.trim().isEmpty) return;
    final userId = await _getOrCreateUserId();
    isLoading = true;

    final contextInfo = ref.read(contextProvider);
    final energy = contextInfo.energyLevel;
    final moodText = _getMoodTranslation(contextInfo.mood);
    final location = contextInfo.currentContext == UserContext.work ? "في العمل" : "غير معروف";
    
    final String remainingTasksStr = tasks.where((t) => !t.isCompleted).map((t) => t.title).join(', ');
    final String goalsStr = goals.map((g) => g.title).join(', ');

    final systemContext = """
أنت 'هوميني'، مساعد ذكي يراعي الحالة النفسية والبدنية والسياقية للمستخدم.
سياق المستخدم الحالي:
- الحالة المزاجية: $moodText.
- مستوى الطاقة البدنية: $energy%.
- المكان الحالي: $location.
- المهام المتبقية: [$remainingTasksStr].
- الأهداف الإستراتيجية: [$goalsStr].

قواعد هامة للرد بناءً على المزاج والطاقة:
1. إذا كان المزاج 'مضغوط' أو الطاقة < 40%: كن موجزاً جداً، رحيماً، ولا تقترح مهاماً صعبة. ركز على المواساة والتشجيع البسيط.
2. إذا كان المزاج 'مركز': أعطه تفاصيل دقيقة وساعده على إنجاز المهام المعقدة.
3. إذا كان المزاج 'سعيد': كن مرحاً وشاركه الحماس.
4. إذا طلب المستخدم إضافة مهمة، ابدأ بـ [ADD_TASK: اسم المهمة].
5. استخدم بيانات الموقع الحالي لتذكيره بمهام مرتبطة بالمكان (إذا كان في العمل).
6. لغة الرد: العربية، ودودة، ومحفزة.
""";

    await _firestore.collection('chats').add(ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()).toMap(userId));

    // --- ميزة اليونيكورن: كسب النقاط عند التفاعل الذكي ---
    int pointsToEarn = userText.length > 50 ? 5 : 2; // 5 نقاط للأسئلة العميقة و2 للقصيرة
    await PointsService.addPoints(pointsToEarn);

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer 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', 
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemContext},
            ...state.take(10).map((m) => {"role": m.isUser ? "user" : "assistant", "content": m.text}),
            {"role": "user", "content": userText}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        String aiResponse = jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
        
        if (aiResponse.contains("[ADD_TASK:")) {
          final startIndex = aiResponse.indexOf("[ADD_TASK:") + 10;
          final endIndex = aiResponse.indexOf("]", startIndex);
          final taskTitle = aiResponse.substring(startIndex, endIndex).trim();
          
          if (_auth.currentUser != null) {
            await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('tasks').add({
              'title': taskTitle, 
              'isCompleted': false, 
              'createdAt': FieldValue.serverTimestamp(),
            });
            // مكافأة إضافية إذا جعل الـ AI يضيف له مهمة تلقائياً!
            await PointsService.addPoints(10);
          }
          aiResponse = aiResponse.replaceRange(aiResponse.indexOf("[ADD_TASK:"), endIndex + 1, "").trim();
        }
        
        await _firestore.collection('chats').add(ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()).toMap(userId));
      }
    } catch (e) {
      print("Error in Groq API: $e");
    } finally {
      isLoading = false;
    }
  }

  Future<void> sendMessage(String text, {List<int>? imageBytes}) async {
    final userId = await _getOrCreateUserId();
    String? base64String = imageBytes != null ? base64Encode(imageBytes) : null;
    
    await _firestore.collection('chats').add(ChatMessage(text: text, isUser: true, base64Image: base64String, timestamp: DateTime.now()).toMap(userId));
    
    // --- ميزة اليونيكورن: كسب نقاط عند إرسال صور للتحليل (أكثر قيمة) ---
    if (base64String != null) {
      await PointsService.addPoints(15); // تحليل الصور يمنح 15 نقطة
    } else if (text.isNotEmpty) {
      await PointsService.addPoints(2);
    }

    String fullAiText = await _askGemini(text.isEmpty ? "ماذا ترى في هذه الصورة؟" : text, base64String);
    await _firestore.collection('chats').add(ChatMessage(text: fullAiText, isUser: false, timestamp: DateTime.now()).toMap(userId));
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) => ChatNotifier(ref));