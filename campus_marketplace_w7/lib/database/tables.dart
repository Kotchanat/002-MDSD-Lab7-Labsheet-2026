
import 'package:drift/drift.dart';

class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get itemId => integer().unique()();

  TextColumn get title => text()();

  RealColumn get price => real()();

  TextColumn get imageUrl => text()();

  DateTimeColumn get addedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ListingDraftRow')
class ListingDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 100)();

  TextColumn get category => text()();

  TextColumn get description => text()();

  TextColumn get imagePath => text()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}