import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import 'my_drafts_page.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const SellItemPage({
    super.key,
    required this.draftRepository,
  });

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final ImagePicker _picker = ImagePicker();

  final GeminiVisionService _visionService =
      GeminiVisionService();

  // false = เรียก Gemini API จริง
  // true = ใช้ข้อมูลจำลองเพื่อทดสอบหน้าจอ
  static const bool _useMockData = false;

  // Prompt สำหรับวิเคราะห์รูปภาพสินค้าจริง
  static const String _prompt = '''
คุณคือผู้ช่วยวิเคราะห์รูปภาพสินค้าเพื่อสร้างประกาศขายสินค้าออนไลน์

โปรดวิเคราะห์รูปภาพสินค้าที่แนบมา และสร้างข้อมูลสำหรับประกาศขายเป็นภาษาไทย

ข้อกำหนด:
1. title: ตั้งชื่อสินค้าให้สั้น กระชับ และเข้าใจง่าย
2. category: ระบุหมวดหมู่สินค้าที่เหมาะสม
3. description: เขียนคำบรรยายสินค้าโดยอ้างอิงจากสิ่งที่มองเห็นได้ในภาพเท่านั้น

ข้อควรระวัง:
- ห้ามเดายี่ห้อ รุ่น ราคา หรือคุณสมบัติที่มองไม่เห็นชัดเจน
- หากระบุรายละเอียดไม่ได้แน่นอน ให้ใช้คำอธิบายทั่วไป
- ใช้ภาษาไทยที่สุภาพ อ่านง่าย และเหมาะกับประกาศขายสินค้า
- ตอบกลับเป็น JSON ที่ถูกต้องเท่านั้น
- ห้ามใส่ Markdown หรือข้อความอื่นนอก JSON

รูปแบบคำตอบ:
{
  "title": "ชื่อสินค้า",
  "category": "หมวดหมู่สินค้า",
  "description": "คำบรรยายสินค้า"
}
''';

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _categoryController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  File? _imageFile;

  ListingDraft? _draft;

  String? _errorMessage;

  bool _isAnalyzing = false;

  // สถานะกำลังบันทึกร่าง
  bool _isSavingDraft = false;

  // ============================================================
  // เลือกรูปภาพสินค้า
  // ============================================================
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (!mounted || pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _draft = null;
        _errorMessage = null;

        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลือกรูปภาพไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  // ============================================================
  // วิเคราะห์รูปภาพสินค้า
  // ============================================================
  Future<void> analyzeProductImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรูปภาพสินค้าก่อน'),
        ),
      );
      return;
    }

    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _draft = null;
      _errorMessage = null;
    });

    try {
      late final ListingDraft result;

      if (_useMockData) {
        // ข้อมูลจำลองสำหรับทดสอบหน้าจอเท่านั้น
        await Future.delayed(
          const Duration(seconds: 1),
        );

        result = ListingDraft.fromJson({
          'title': 'น้ำหอมขวดสีแดง',
          'category': 'ความงามและของใช้ส่วนตัว',
          'description':
              'น้ำหอมบรรจุในขวดสีแดงพร้อมฝาสีดำ '
              'โปรดตรวจสอบรายละเอียดสินค้าก่อนลงประกาศ',
        });
      } else {
        // เรียก Gemini API จริง
        result = await _visionService.analyzeProductImage(
          _imageFile!,
          prompt: _prompt,
        );
      }

      if (!mounted) return;

      setState(() {
        _draft = result;
        _titleController.text = result.title;
        _categoryController.text = result.category;
        _descriptionController.text = result.description;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  // ============================================================
  // ยืนยันและบันทึกร่างประกาศลงฐานข้อมูล
  // ============================================================
  Future<void> confirmDraft() async {
    if (_draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาให้ AI ช่วยแนะนำก่อน'),
        ),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรูปภาพสินค้าก่อน'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        category.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบก่อนยืนยัน'),
        ),
      );
      return;
    }

    if (_isSavingDraft) return;

    // สร้าง ListingDraft จากข้อมูลที่ผู้ใช้ตรวจสอบ/แก้ไขแล้ว
    final draft = ListingDraft.fromJson({
      'title': title,
      'category': category,
      'description': description,
    });

    setState(() {
      _isSavingDraft = true;
      _errorMessage = null;
    });

    try {
      // บันทึกร่างลงฐานข้อมูล Drift แบบถาวร
      await widget.draftRepository.saveDraft(
        draft,
        _imageFile!.path,
      );

      if (!mounted) return;

      // ล้างข้อมูลหลังบันทึกสำเร็จเท่านั้น
      setState(() {
        _imageFile = null;
        _draft = null;
        _errorMessage = null;

        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();

        _isSavingDraft = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'บันทึกร่างประกาศเรียบร้อยแล้ว',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSavingDraft = false;
        _errorMessage =
            'บันทึกร่างประกาศไม่สำเร็จ: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกร่างประกาศไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // Dispose
  // ============================================================
  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        centerTitle: true,

        // ปุ่มเข้าสู่หน้าร่างประกาศของฉัน
        actions: [
          IconButton(
            tooltip: 'ร่างประกาศของฉัน',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MyDraftsPage(
                    repository: widget.draftRepository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'รูปภาพสินค้า',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
              ),
              child: _imageFile == null
                  ? const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ยังไม่ได้เลือกรูปภาพ',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _isAnalyzing || _isSavingDraft
                      ? null
                      : pickImage,
              icon: const Icon(
                Icons.photo_library_outlined,
              ),
              label: const Text(
                'เลือกรูปภาพสินค้า',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed:
                  _isAnalyzing || _isSavingDraft
                      ? null
                      : analyzeProductImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'ให้ AI ช่วยแนะนำ',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isAnalyzing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _useMockData
                            ? 'กำลังเตรียมข้อมูลตัวอย่าง...'
                            : 'AI กำลังวิเคราะห์ภาพสินค้า...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            if (_isSavingDraft)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'กำลังบันทึกร่างประกาศ...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            if (_draft != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _useMockData
                                  ? 'ผลลัพธ์ตัวอย่าง (Mock Data)'
                                  : 'ผลการวิเคราะห์จาก AI',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _useMockData
                            ? 'ข้อมูลนี้ใช้สำหรับทดสอบหน้าจอเท่านั้น'
                            : 'ตรวจสอบและแก้ไขข้อมูลก่อนยืนยัน',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const Divider(height: 24),

                      const Text(
                        'ชื่อประกาศ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextField(
                        controller: _titleController,
                        decoration:
                            const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'กรอกชื่อประกาศ',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'หมวดหมู่',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextField(
                        controller: _categoryController,
                        decoration:
                            const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'กรอกหมวดหมู่',
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'คำบรรยาย',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextField(
                        controller:
                            _descriptionController,
                        decoration:
                            const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'กรอกคำบรรยายสินค้า',
                        ),
                        maxLines: 5,
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isAnalyzing ||
                                      _isSavingDraft
                                  ? null
                                  : confirmDraft,
                          icon: _isSavingDraft
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check,
                                ),
                          label: Text(
                            _isSavingDraft
                                ? 'กำลังบันทึกร่าง...'
                                : 'ยืนยันร่างประกาศ',
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เกิดข้อผิดพลาด',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      SelectableText(
                        _errorMessage!,
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment:
                            Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              _isAnalyzing ||
                                      _isSavingDraft
                                  ? null
                                  : analyzeProductImage,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'ลองอีกครั้ง',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}