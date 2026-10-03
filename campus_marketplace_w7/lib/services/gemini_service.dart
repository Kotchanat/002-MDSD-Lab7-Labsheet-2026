
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = 'gemini-3.8-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ GEMINI_API_KEY กรุณาตรวจสอบคำสั่ง flutter run',
      );
    }

    final uri = Uri.parse('$_baseUrl/$_model:generateContent');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API Error: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final candidates = data['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini ไม่ได้ส่ง candidates กลับมา');
    }

    final candidate = candidates.first;

    if (candidate is! Map) {
      throw Exception('รูปแบบคำตอบจาก Gemini ไม่ถูกต้อง');
    }

    final content = candidate['content'];

    if (content is! Map) {
      throw Exception('Gemini ไม่ได้ส่ง content กลับมา');
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception('Gemini ไม่ได้ส่งข้อความกลับมา');
    }

    final result = parts
        .where((part) => part is Map && part['text'] != null)
        .map((part) => part['text'].toString())
        .join('\n')
        .trim();

    if (result.isEmpty) {
      throw Exception('ไม่พบข้อความคำตอบจาก Gemini');
    }

    return result;
  }
}