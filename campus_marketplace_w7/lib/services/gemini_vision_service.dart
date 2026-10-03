
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = 'gemini-3.8-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<ListingDraft> analyzeProductImage(
    File imageFile, {
    required String prompt,
  }) async {
    // 1. ตรวจสอบ API Key
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ GEMINI_API_KEY กรุณาตรวจสอบคำสั่ง flutter run',
      );
    }

    // 2. ตรวจสอบไฟล์ภาพ
    if (!await imageFile.exists()) {
      throw Exception('ไม่พบไฟล์ภาพสินค้าที่เลือก');
    }

    // 3. อ่านภาพและแปลงเป็น Base64
    final imageBytes = await imageFile.readAsBytes();

    if (imageBytes.isEmpty) {
      throw Exception('ไฟล์ภาพว่างเปล่า กรุณาเลือกรูปภาพใหม่');
    }

    final base64Image = base64Encode(imageBytes);
    final mimeType = _getMimeType(imageFile.path);

    // 4. สร้าง URL สำหรับ Gemini API
    final uri = Uri.parse(
      '$_baseUrl/$_model:generateContent',
    );

    // 5. ส่งคำขอไปยัง Gemini
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
                  {
                    'inlineData': {
                      'mimeType': mimeType,
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'responseSchema': {
                'type': 'OBJECT',
                'properties': {
                  'title': {'type': 'STRING'},
                  'category': {'type': 'STRING'},
                  'description': {'type': 'STRING'},
                },
                'required': [
                  'title',
                  'category',
                  'description',
                ],
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 120));

    // 6. ตรวจสอบ HTTP Status
    if (response.statusCode == 429) {
      throw Exception(
        'Gemini API ใช้โควตาเกินขีดจำกัด '
        'กรุณาตรวจสอบโควตาและลองใหม่ภายหลัง',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API Error: '
        '${response.statusCode} ${response.body}',
      );
    }

    // 7. แปลง Response เป็น JSON
    final Map<String, dynamic> responseData;

    try {
      responseData =
          jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Gemini ส่งข้อมูลกลับมาในรูปแบบที่ไม่ถูกต้อง');
    } on TypeError {
      throw Exception('รูปแบบข้อมูลที่ได้รับจาก Gemini ไม่ถูกต้อง');
    }

    // 8. ตรวจสอบว่าคำขอถูกบล็อกก่อนสร้างคำตอบหรือไม่
    final promptFeedback = responseData['promptFeedback'];

    if (promptFeedback is Map &&
        promptFeedback['blockReason'] == 'SAFETY') {
      throw Exception(
        'คำขอถูกบล็อกเนื่องจากไม่ผ่านการตรวจสอบความปลอดภัย '
        'ตามนโยบายของ Gemini',
      );
    }

    // 9. ตรวจสอบ Candidates
    final candidates = responseData['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception(
        'Gemini ไม่ได้ส่งผลการวิเคราะห์กลับมา '
        'กรุณาตรวจสอบสถานะคำขอและลองใหม่',
      );
    }

    final candidate = candidates.first;

    if (candidate is! Map) {
      throw Exception('รูปแบบผลการวิเคราะห์ไม่ถูกต้อง');
    }

    // 10. ตรวจสอบเหตุผลที่ Gemini หยุดสร้างคำตอบ
    final finishReason = candidate['finishReason'];

    if (finishReason == 'SAFETY') {
      throw Exception(
        'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัย '
        'ตามนโยบายของ Gemini กรุณาใช้ภาพหรือคำขออื่น',
      );
    }

    if (finishReason != null &&
        finishReason != 'STOP') {
      throw Exception(
        'Gemini ไม่สามารถสร้างคำตอบจนเสร็จสมบูรณ์ '
        '(finishReason: $finishReason)',
      );
    }

    // 11. ตรวจสอบ Content
    final content = candidate['content'];

    if (content is! Map) {
      throw Exception('ไม่พบ content จาก Gemini');
    }

    // 12. ตรวจสอบ Parts
    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception(
        'ไม่พบข้อความผลการวิเคราะห์จาก Gemini',
      );
    }

    // 13. รวมข้อความคำตอบ
    final resultText = parts
        .where(
          (part) =>
              part is Map && part['text'] != null,
        )
        .map(
          (part) => part['text'].toString(),
        )
        .join('\n')
        .trim();

    if (resultText.isEmpty) {
      throw Exception(
        'ผลการวิเคราะห์จาก Gemini เป็นค่าว่าง',
      );
    }

    // 14. แปลง JSON เป็น ListingDraft
    try {
      final decoded = jsonDecode(resultText);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'ผลลัพธ์ไม่ใช่ JSON Object',
        );
      }

      final result = ListingDraft.fromJson(decoded);

      if (result.title.trim().isEmpty ||
          result.category.trim().isEmpty ||
          result.description.trim().isEmpty) {
        throw const FormatException(
          'ข้อมูลสินค้าไม่ครบถ้วน',
        );
      }

      return result;
    } on FormatException {
      throw Exception(
        'ไม่สามารถแปลงผลลัพธ์จาก Gemini '
        'เป็นข้อมูลสินค้าได้ กรุณาลองใหม่',
      );
    } on TypeError {
      throw Exception(
        'ข้อมูลสินค้าที่ได้รับมีรูปแบบไม่ถูกต้อง',
      );
    }
  }

  // 15. ตรวจสอบชนิดไฟล์ภาพ
  String _getMimeType(String path) {
    final lowerPath = path.toLowerCase();

    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lowerPath.endsWith('.gif')) {
      return 'image/gif';
    }

    if (lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    throw Exception(
      'ไม่รองรับไฟล์ภาพชนิดนี้ กรุณาใช้ JPG, PNG หรือ WEBP',
    );
  }
}