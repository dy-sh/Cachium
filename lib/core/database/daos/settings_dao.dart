import 'package:drift/drift.dart';

import '../app_database.dart';

part 'settings_dao.g.dart';

/// Data Access Object for app settings operations.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Insert or update app settings
  Future<void> upsert({
    required String id,
    required int lastUpdatedAt,
    required String jsonData,
  }) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        jsonData: jsonData,
      ),
    );
  }

  /// Get app settings by ID
  Future<AppSetting?> getById(String id) async {
    return (select(appSettings)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Check if settings exist
  Future<bool> exists(String id) async {
    final result = await getById(id);
    return result != null;
  }

  /// Delete all app settings from the database
  Future<void> deleteAll() async {
    await delete(appSettings).go();
  }
}
