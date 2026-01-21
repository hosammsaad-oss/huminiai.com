import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // المفتاح الذي زودتني به
  static const String _apiKey = 'AIzaSyDpKkg_1-o5jE9Hmy8Ei_H_6hcWNgB8-IQ'; 
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
        );

  /// دالة لإرسال النصوص والصور إلى جيميني
  Future<String> getGeminiResponse(String prompt, {String? base64Image}) async {
    try {
      final List<Part> parts = [TextPart(prompt)];

      // إذا كانت هناك صورة، نقوم بمعالجتها وإضافتها
      if (base64Image != null) {
        // تنظيف نص الـ base64 من أي زوائد
        final String cleanBase64 = base64Image.contains(',') 
            ? base64Image.split(',').last 
            : base64Image;
            
        parts.add(DataPart('image/jpeg', base64Decode(cleanBase64)));
      }

      final content = [Content.multi(parts)];
      final response = await _model.generateContent(content);
      
      return response.text ?? "عذراً، لم أستطع صياغة رد مناسب.";
    } catch (e) {
      return "خطأ في الاتصال بجيميني: $e";
    }
  }
}