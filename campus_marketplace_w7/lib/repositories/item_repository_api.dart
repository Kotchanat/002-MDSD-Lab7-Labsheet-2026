import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'ไม่สามารถโหลดรายการสินค้าได้ '
        '(สถานะ ${response.statusCode})',
      );
    } on TimeoutException {
      return _fallbackItems();
    } on http.ClientException {
      return _fallbackItems();
    } on FormatException {
      return _fallbackItems();
    } catch (e) {
      return _fallbackItems();
    }
  }

  /// ข้อมูลสำรองสำหรับทดสอบระบบ Favorites
  /// ใช้เฉพาะกรณี Fake Store API ไม่สามารถเชื่อมต่อได้
  List<Item> _fallbackItems() {
    return const [
      Item(
        id: 101,
        title: 'เสื้อยืด Campus',
        price: 199.0,
        description: 'เสื้อยืดสำหรับนักศึกษา',
        category: 'เสื้อผ้า',
        imageUrl: 'https://picsum.photos/seed/campus-shirt/200/200',
      ),
      Item(
        id: 102,
        title: 'กระเป๋านักศึกษา',
        price: 350.0,
        description: 'กระเป๋าสำหรับใส่หนังสือและอุปกรณ์การเรียน',
        category: 'กระเป๋า',
        imageUrl: 'https://picsum.photos/seed/campus-bag/200/200',
      ),
      Item(
        id: 103,
        title: 'หูฟังไร้สาย',
        price: 590.0,
        description: 'หูฟังไร้สายสำหรับฟังเพลงและเรียนออนไลน์',
        category: 'อุปกรณ์อิเล็กทรอนิกส์',
        imageUrl: 'https://picsum.photos/seed/campus-headphone/200/200',
      ),
    ];
  }
}