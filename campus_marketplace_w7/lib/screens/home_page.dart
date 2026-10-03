
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';
import 'sell_item_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;

  const HomePage({
    super.key,
    required this.repository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;
  bool _isTestingGemini = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  // ทดสอบเรียกใช้งาน Gemini API
  Future<void> testGemini() async {
    if (_isTestingGemini) return;

    setState(() {
      _isTestingGemini = true;
    });

    try {
      final result = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTestingGemini = false;
        });
      }
    }
  }

  // เปิดหน้าลงประกาศขายสินค้า
  void openSellItemPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const SellItemPage(),
      ),
    );
  }

  // เปิดหน้าตะกร้าสินค้า
  void openCheckoutPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const CheckoutPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            tooltip: 'ตะกร้าสินค้า',
            icon: Badge(
              label: Text(
                '${context.watch<CartModel>().itemCount}',
              ),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: openCheckoutPage,
          ),
        ],
      ),
      body: Column(
        children: [
          // ปุ่มทดสอบ Gemini API
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isTestingGemini ? null : testGemini,
                icon: _isTestingGemini
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.smart_toy),
                label: Text(
                  _isTestingGemini
                      ? 'กำลังติดต่อ Gemini...'
                      : 'ทดสอบ Gemini API',
                ),
              ),
            ),
          ),

          // ปุ่มลงประกาศขายสินค้า
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openSellItemPage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('ลงประกาศขายสินค้า'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // รายการสินค้าเดิมจาก Repository
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'เกิดข้อผิดพลาดในการโหลดสินค้า:\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('ไม่พบสินค้า'),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ListTile(
                      leading: Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons.broken_image,
                          );
                        },
                      ),
                      title: Text(item.title),
                      subtitle: Text('${item.price} บาท'),
                      trailing: IconButton(
                        tooltip: 'เพิ่มลงตะกร้า',
                        icon: const Icon(
                          Icons.add_shopping_cart,
                        ),
                        onPressed: () {
                          context.read<CartModel>().add(item);

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'เพิ่ม "${item.title}" ลงตะกร้าแล้ว',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}