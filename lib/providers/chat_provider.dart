import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// استيراد الموديلات والخدمات
import 'life_provider.dart';
import 'goals_provider.dart';
import '../services/context_service.dart';
import '../services/points_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? base64Image;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.base64Image,
    required this.timestamp,
  });

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
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool isLoading = false;
  String? _cachedUserId;

  // وظيفة لاستدعاء أنيميشن النجاح في الـ UI
  Function(int points)? onAchievementUnlocked;

  final _geminiModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: '');

  ChatNotifier(this.ref) : super([]) {
    _initAndLoadMessages();
  }

  // --- [تحديث] محرك تحليل الإشعارات الخارجية المطور ---
  Future<void> analyzeExternalNotification(String notificationText) async {
    // 1. فلتر الكلمات المفتاحية السريع (Pre-filter) لتوفير الـ API والوقت
    final noiseWords = [
      "خصم",
      "عرض",
      "مبروك",
      "اشترك",
      "تم تحديث",
      "جاري التحميل",
      "كود خصم",
      "تسوق الآن",
      "طلبك قيد التنفيذ",
      "شكراً لاستخدامك",
    ];

    // تحويل النص للصغير للتحقق الشامل
    if (noiseWords.any((word) => notificationText.contains(word))) {
      return; // تجاهل فوري للإشعارات الإعلانية والتقنية
    }

    try {
      final userId = await _getOrCreateUserId();

      // 2. تحديث الـ Prompt لجعل الوكيل أكثر حزماً وذكاءً (Logic Update)
      final agentPrompt =
          """
أنت 'هوميني' الوكيل الذكي والمساعد الشخصي الصارم. لقد التقطت الإشعار التالي:
"$notificationText"

بروتوكول التحليل:
1. صنف الإشعار: هل هو (موعد، طلب شراء، مهمة عمل، أو حدث هام)؟
2. إذا كان إجتماعياً بسيطاً (ضحك، سلام، رموز) أو غير مفيد إدارياً: رد بكلمة IGNORE فقط.
3. إذا كان مهماً: اقترح إجراءً عملياً سريعاً (سؤال) بأسلوب محفز وقصير جداً (لا يتجاوز 12 كلمة).

أمثلة للرد الذكي:
- "وصلك طلب شراء، هل أضيفه لقائمة مهامك؟ 🛒"
- "لديك موعد غداً، هل تريد مني تذكيرك؟ ⏰"
""";

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": agentPrompt},
          ],
          "temperature": 0.3, // خفض الحرارة لقرار أكثر دقة (IGNORE vs ACTION)
        }),
      );

      if (response.statusCode == 200) {
        String aiDecision = jsonDecode(
          utf8.decode(response.bodyBytes),
        )['choices'][0]['message']['content'];

        if (aiDecision.trim().toUpperCase() != "IGNORE") {
          // إضافة اقتراح الوكيل كرسالة في الشات مع تمييزها
          final agentMsg = ChatMessage(
            text: "🤖 **اقتراح ذكي:** $aiDecision",
            isUser: false,
            timestamp: DateTime.now(),
          );

          await _firestore.collection('chats').add(agentMsg.toMap(userId));

          // إرسال إشعار داخلي لتنبيه المستخدم بالاقتراح
          _sendSystemNotification("تنبيه من هوميني ✨", aiDecision);
        }
      }
    } catch (e) {
      print("Error analyzing notification: $e");
    }
  }

  void _sendSystemNotification(String title, String body) async {
    const details = AndroidNotificationDetails(
      'agent_suggestions',
      'اقتراحات الوكيل',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      99,
      title,
      body,
      const NotificationDetails(android: details),
    );
  }

  // --- مهارة الوكيل لمنح نقاط الإنجاز ---
  Future<void> _agentGrantAchievementPoints() async {
    final user = _auth.currentUser;
    if (user == null) return;

    const int pointsAwarded = 50;
    await PointsService.addPoints(pointsAwarded);
    _sendAchievementNotification();

    if (onAchievementUnlocked != null) {
      onAchievementUnlocked!(pointsAwarded);
    }
  }

  void _sendAchievementNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'agent_reward',
      'مكافآت الوكيل',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      1,
      "إنجاز عظيم! 💎",
      "لقد قيم هوميني إنجازك ومنحك 50 نقطة إضافية.",
      const NotificationDetails(android: androidDetails),
    );
  }

  // --- نظام التحدي اليومي ---
  Future<void> _processDailyChallenge() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final userDoc = _firestore.collection('users').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) return;
        final data = snapshot.data() as Map<String, dynamic>;
        String lastDate = data['lastChallengeDate'] ?? "";
        int chatCount = data['dailyChatCount'] ?? 0;
        bool isRewarded = data['challengeCompleted'] ?? false;

        if (lastDate != today) {
          chatCount = 1;
          isRewarded = false;
        } else {
          chatCount++;
        }

        transaction.update(userDoc, {
          'dailyChatCount': chatCount,
          'lastChallengeDate': today,
        });

        if (chatCount == 3 && !isRewarded) {
          transaction.update(userDoc, {
            'points': FieldValue.increment(50),
            'challengeCompleted': true,
          });
          _sendCompletionNotification();
        }
      });
    } catch (e) {
      print("Challenge Error: $e");
    }
  }

  void _sendCompletionNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'challenge_done',
      'تحديات هوميني',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      0,
      "كفو يا بطل! 🏆",
      "أكملت تحدي اليوم وحصلت على 50 نقطة مكافأة.",
      const NotificationDetails(android: androidDetails),
    );
  }

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
    _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          state = snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              text: data['text'] ?? "",
              isUser: data['isUser'] ?? true,
              base64Image: data['base64Image'],
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  Future<void> pickAndSendImage(List<TaskModel> tasks, List<Goal> goals) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await sendMessage(
      "حلل هذه الصورة بناءً على سياق مهامي وأهدافي",
      imageBytes: bytes,
    );
  }

  Future<void> sendSmartMessage(
    String userText,
    List<TaskModel> tasks,
    List<Goal> goals,
  ) async {
    if (userText.trim().isEmpty) return;
    final userId = await _getOrCreateUserId();

    isLoading = true;
    await _processDailyChallenge();

    final contextInfo = ref.read(contextProvider);
    final energy = contextInfo.energyLevel;
    final moodText = _getMoodTranslation(contextInfo.mood);
    final String remainingTasksStr = tasks
        .where((t) => !t.isCompleted)
        .map((t) => t.title)
        .join(', ');
    final String goalsStr = goals.map((g) => g.title).join(', ');

    final systemContext =
        """
أنت 'هوميني'، وكيل ذكاء اصطناعي صارم وذكي يساعد المستخدم على تحقيق أهدافه.
سياق المستخدم: مزاج $moodText، طاقة $energy%، مهام [$remainingTasksStr].

قواعدك الصارمة كوكيل:
1. بروتوكول النقاط: لا تمنح الكود [GRANT_ACHIEVEMENT_POINTS] بمجرد ادعاء المستخدم للإنجاز. 
   - أولاً: اسأله سؤالاً ذكياً للتأكد من قيامه بالمهمة فعلاً.
   - ثانياً: إذا كانت إجابته مقنعة، أرسل الكود [GRANT_ACHIEVEMENT_POINTS].
2. إضافة المهام: إذا اقترح المستخدم فعلاً مستقبلياً، أضف الكود: [ADD_TASK: عنوان المهمة].
3. كن محفزاً وصريحاً باللغة العربية.
""";

    await _firestore
        .collection('chats')
        .add(
          ChatMessage(
            text: userText,
            isUser: true,
            timestamp: DateTime.now(),
          ).toMap(userId),
        );

    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization':
                  'Bearer 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',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "messages": [
                {"role": "system", "content": systemContext},
                ...state.reversed
                    .take(6)
                    .toList()
                    .reversed
                    .map(
                      (m) => {
                        "role": m.isUser ? "user" : "assistant",
                        "content": m.text,
                      },
                    ),
                {"role": "user", "content": userText},
              ],
              "temperature": 0.7,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String aiResponse = jsonDecode(
          utf8.decode(response.bodyBytes),
        )['choices'][0]['message']['content'];

        if (aiResponse.contains("[GRANT_ACHIEVEMENT_POINTS]")) {
          await _agentGrantAchievementPoints();
          aiResponse = aiResponse
              .replaceAll("[GRANT_ACHIEVEMENT_POINTS]", "")
              .trim();
        }

        if (aiResponse.contains("[ADD_TASK:")) {
          final startIndex = aiResponse.indexOf("[ADD_TASK:") + 10;
          final endIndex = aiResponse.indexOf("]", startIndex);
          final taskTitle = aiResponse.substring(startIndex, endIndex).trim();

          if (_auth.currentUser != null) {
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('tasks')
                .add({
                  'title': taskTitle,
                  'isCompleted': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
            await PointsService.addPoints(10);
          }
          aiResponse = aiResponse
              .replaceRange(aiResponse.indexOf("[ADD_TASK:"), endIndex + 1, "")
              .trim();
        }

        await _firestore
            .collection('chats')
            .add(
              ChatMessage(
                text: aiResponse,
                isUser: false,
                timestamp: DateTime.now(),
              ).toMap(userId),
            );
      }
    } catch (e) {
      print("Error in SmartMessage: $e");
    } finally {
      isLoading = false;
    }
  }

  String _getMoodTranslation(UserMood mood) {
    switch (mood) {
      case UserMood.happy:
        return "سعيد";
      case UserMood.stressed:
        return "متوتر";
      case UserMood.focused:
        return "مركز";
      case UserMood.tired:
        return "متعب";
      case UserMood.neutral:
        return "طبيعي";
    }
  }

  Future<void> sendMessage(String text, {List<int>? imageBytes}) async {
    final userId = await _getOrCreateUserId();
    await _processDailyChallenge();
    String? base64String = imageBytes != null ? base64Encode(imageBytes) : null;
    await _firestore
        .collection('chats')
        .add(
          ChatMessage(
            text: text,
            isUser: true,
            base64Image: base64String,
            timestamp: DateTime.now(),
          ).toMap(userId),
        );

    if (base64String != null) {
      await PointsService.addPoints(15);
    } else if (text.isNotEmpty) {
      await PointsService.addPoints(2);
    }

    String fullAiText = await _askGemini(
      text.isEmpty ? "ماذا ترى في هذه الصورة؟" : text,
      base64String,
    );
    await _firestore
        .collection('chats')
        .add(
          ChatMessage(
            text: fullAiText,
            isUser: false,
            timestamp: DateTime.now(),
          ).toMap(userId),
        );
  }

  Future<String> _askGemini(String text, String? base64Image) async {
    try {
      final List<Part> parts = [TextPart(text)];
      if (base64Image != null) {
        final bytes = base64Decode(
          base64Image.contains(',') ? base64Image.split(',').last : base64Image,
        );
        parts.add(DataPart('image/jpeg', bytes));
      }
      final response = await _geminiModel.generateContent([
        Content.multi(parts),
      ]);
      return response.text ?? "تم التحليل بنجاح.";
    } catch (e) {
      return "خطأ في Gemini: $e";
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(ref),
);
