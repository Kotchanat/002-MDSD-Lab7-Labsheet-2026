import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift
    implements ListingDraftRepository {
  final AppDatabase _db;

  ListingDraftRepositoryDrift(this._db);

  // Create: บันทึกร่างประกาศขายสินค้า
  @override
  Future<void> saveDraft(
    ListingDraft draft,
    String imagePath,
  ) {
    return _db.into(_db.listingDrafts).insert(
          ListingDraftsCompanion.insert(
            title: draft.title,
            category: draft.category,
            description: draft.description,
            imagePath: imagePath,
          ),
        );
  }

  // Read: อ่านร่างประกาศทั้งหมด
  // เรียงจากรายการที่แก้ไขล่าสุดไปเก่าสุด
  @override
  Future<List<ListingDraftRow>> getAllDrafts() {
    return (_db.select(_db.listingDrafts)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  // Delete: ลบร่างประกาศ
  @override
  Future<void> deleteDraft(int id) {
    return (_db.delete(_db.listingDrafts)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}