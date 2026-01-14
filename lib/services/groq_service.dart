import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:humini_ai/core/constants.dart';
class GroqService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    validateStatus: (status) => status! < 500, // للسماح بقراءة أخطاء الـ 400
  ));

  Future<String> getAIResponse(String prompt, {Uint8List? imageBytes}) async {
    try {
      // 1. إعداد البيانات الأساسية
      String model = imageBytes != null ? "llama-3.2-11b-vision-preview" : "llama-3.3-70b-versatile";
      
      List<Map<String, dynamic>> messages = [];
      
      // إضافة رسالة النظام
      messages.add({
        "role": "system",
        "content": "أنت Humini AI، مساعد ذكي. أجب دائماً بالعربية."
      });

      // 2. بناء رسالة المستخدم بناءً على النوع
      if (imageBytes != null) {
        String base64Image = base64Encode(imageBytes);
        messages.add({
          "role": "user",
          "content": [
            {"type": "text", "text": prompt.isEmpty ? "ماذا يوجد في هذه الصورة؟" : prompt},
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
            }
          ]
        });
      } else {
        messages.add({
          "role": "user", 
          "content": prompt
        });
      }

      // 3. الإرسال للسيرفر
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(
          headers: {
            "Authorization": "Bearer ${AppConstants.groqAccountsKey.trim()}",
            "Content-Type": "application/json",
          },
        ),
        data: {
          "model": model,
          "messages": messages,
          "temperature": 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      } else {
        // طباعة الخطأ القادم من Groq لمعرفته بالتحديد
        print("Groq API Error: ${response.data}");
        return "خطأ من السيرفر: ${response.data['error']['message'] ?? 'فشل الطلب'}";
      }
    } catch (e) {
      print("Service Error: $e");
      return "عذراً، حدث خطأ في الاتصال. تأكد من جودة الإنترنت ومفتاح API.";
    }
  }
}