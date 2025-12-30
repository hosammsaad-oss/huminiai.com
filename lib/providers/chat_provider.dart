import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final String? base64Image;

  ChatMessage({required this.text, required this.isUser, this.base64Image});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser, 'image': base64Image};
  factory ChatMessage.fromJson(Map<String, dynamic> json) => 
      ChatMessage(text: json['text'], isUser: json['isUser'], base64Image: json['image']);
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) => ChatNotifier());

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]) {
    _loadChatHistory();
  }

  bool isLoading = false;
  // مفتاح Groq الخاص بك
  final String _groqApiKey = "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";

  Future<void> sendMessage(String text, {Uint8List? imageBytes}) async {
    if (text.isEmpty && imageBytes == null) return;

    String? base64Image;
    if (imageBytes != null) base64Image = base64Encode(imageBytes);

    final userMsg = ChatMessage(text: text, isUser: true, base64Image: base64Image);
    state = [...state, userMsg];
    await _saveChatHistory();

    isLoading = true;
    state = [...state]; 

    try {
      // 1. تحديد الموديل (Llama 3.2 للصور و Llama 3 لـ النصوص)
      final String modelId = imageBytes != null 
          ? "llama-3.2-11b-vision-preview" 
          : "llama3-8b-8192";

      // 2. بناء محتوى الرسالة بناءً على نوع المدخلات
      dynamic content;
      if (imageBytes != null) {
        content = [
          {"type": "text", "text": text.isEmpty ? "ماذا ترى في هذه الصورة؟" : text},
          {
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          }
        ];
      } else {
        content = text; // للنصوص العادية نرسل النص مباشرة
      }

      // 3. إرسال الطلب إلى Groq
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": [
            {
              "role": "user",
              "content": content
            }
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiText = data['choices'][0]['message']['content'];
        state = [...state, ChatMessage(text: aiText, isUser: false)];
        await _saveChatHistory();
      } else {
        // استخراج رسالة الخطأ الحقيقية من الخادم
        final errorBody = jsonDecode(response.body);
        String errorMessage = errorBody['error']['message'] ?? "خطأ غير معروف";
        state = [...state, ChatMessage(text: "تنبيه: $errorMessage", isUser: false)];
      }
    } catch (e) {
      state = [...state, ChatMessage(text: "حدث خطأ في الاتصال. تأكد من إيقاف حماية الويب CORS.", isUser: false)];
    } finally {
      isLoading = false;
      state = [...state];
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(state.map((m) => m.toJson()).toList()));
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('chat_history');
    if (data != null) {
      state = (jsonDecode(data) as List).map((m) => ChatMessage.fromJson(m)).toList();
    }
  }

  void clearChat() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}