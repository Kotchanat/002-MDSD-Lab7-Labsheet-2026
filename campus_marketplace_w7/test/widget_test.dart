import 'package:flutter_test/flutter_test.dart';
import 'package:campus_marketplace_w7/models/item.dart';

void main() {
  test('Item model can be created from JSON', () {
    final item = Item.fromJson({
      'id': 1,
      'title': 'Test Product',
      'price': 100,
      'description': 'Test description',
      'category': 'Test category',
      'image': 'https://example.com/image.jpg',
    });

    expect(item.id, 1);
    expect(item.title, 'Test Product');
    expect(item.price, 100.0);
    expect(item.category, 'Test category');
    expect(item.imageUrl, 'https://example.com/image.jpg');
  });
}