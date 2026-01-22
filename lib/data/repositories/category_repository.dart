import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../features/categories/data/models/category.dart' as ui;
import '../models/category_data.dart';

/// Repository for managing encrypted category storage.
///
/// Converts between UI Category models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
class CategoryRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  CategoryRepository({
    required this.database,
    required this.encryptionService,
  });

  /// Convert UI Category to internal CategoryData for encryption
  CategoryData _toData(ui.Category category) {
    return CategoryData(
      id: category.id,
      name: category.name,
      iconCodePoint: category.icon.codePoint,
      iconFontFamily: category.icon.fontFamily ?? 'lucide',
      iconFontPackage: category.icon.fontPackage,
      colorIndex: category.colorIndex,
      type: category.type.name,
      isCustom: category.isCustom,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
    );
  }

  /// Convert internal CategoryData to UI Category
  ui.Category _toCategory(CategoryData data) {
    return ui.Category(
      id: data.id,
      name: data.name,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily,
        fontPackage: data.iconFontPackage,
      ),
      colorIndex: data.colorIndex,
      type: ui.CategoryType.values.firstWhere(
        (t) => t.name == data.type,
        orElse: () => ui.CategoryType.expense,
      ),
      isCustom: data.isCustom,
      parentId: data.parentId,
      sortOrder: data.sortOrder,
    );
  }

  /// Create a new category (encrypt and insert)
  Future<void> createCategory(ui.Category category) async {
    final data = _toData(category);
    final encryptedBlob = await encryptionService.encryptCategory(data);

    await database.insertCategory(
      id: category.id,
      sortOrder: category.sortOrder,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Create or update a category (encrypt and upsert)
  Future<void> upsertCategory(ui.Category category) async {
    final data = _toData(category);
    final encryptedBlob = await encryptionService.encryptCategory(data);

    await database.upsertCategory(
      id: category.id,
      sortOrder: category.sortOrder,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Get a single category by ID (fetch, decrypt, verify)
  Future<ui.Category?> getCategory(String id) async {
    final row = await database.getCategory(id);
    if (row == null) return null;

    final data = await encryptionService.decryptCategory(
      row.encryptedBlob,
      expectedId: row.id,
      expectedSortOrder: row.sortOrder,
    );

    return _toCategory(data);
  }

  /// Get all non-deleted categories
  Future<List<ui.Category>> getAllCategories() async {
    final rows = await database.getAllCategories();
    final categories = <ui.Category>[];

    for (final row in rows) {
      final data = await encryptionService.decryptCategory(
        row.encryptedBlob,
        expectedId: row.id,
        expectedSortOrder: row.sortOrder,
      );
      categories.add(_toCategory(data));
    }

    return categories;
  }

  /// Update an existing category (re-encrypt and update)
  Future<void> updateCategory(ui.Category category) async {
    final data = _toData(category);
    final encryptedBlob = await encryptionService.encryptCategory(data);

    await database.updateCategory(
      id: category.id,
      sortOrder: category.sortOrder,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Soft delete a category (set isDeleted = true)
  Future<void> deleteCategory(String id) async {
    await database.softDeleteCategory(
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Watch all categories (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  Stream<List<ui.Category>> watchAllCategories() {
    return database.watchAllCategories().asyncMap((rows) async {
      final categories = <ui.Category>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decryptCategory(
            row.encryptedBlob,
            expectedId: row.id,
            expectedSortOrder: row.sortOrder,
          );
          categories.add(_toCategory(data));
        } catch (_) {
          // Skip corrupted rows in stream
          continue;
        }
      }

      return categories;
    });
  }

  /// Check if any categories exist in the database
  Future<bool> hasCategories() async {
    return database.hasCategories();
  }

  /// Seed default categories (call on first run)
  Future<void> seedDefaultCategories() async {
    final defaults = ui.DefaultCategories.all;
    for (final category in defaults) {
      await upsertCategory(category);
    }
  }
}
