import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;

  FavoritesRepositoryDrift(this._db);

  // Create: เพิ่มสินค้าลงรายการโปรด
  @override
  Future<void> addFavorite(
    int itemId,
    String title,
    double price,
    String imageUrl,
  ) {
    return _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // Read: อ่านรายการโปรดทั้งหมด
  // เรียงจากรายการที่กดล่าสุดไปเก่าสุด
  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    return (_db.select(_db.favoriteItems)
          ..orderBy([
            (t) => OrderingTerm.desc(t.addedAt),
          ]))
        .get();
  }

  // Delete: ลบสินค้าจากรายการโปรด
  @override
  Future<void> removeFavorite(int itemId) {
    return (_db.delete(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}