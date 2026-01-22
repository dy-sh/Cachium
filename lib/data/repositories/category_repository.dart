import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/categories/data/models/category.dart' as ui;
import '../encryption/category_data.dart';

/// Repository for managing encrypted category storage.
///
/// Converts between UI Category models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
///
/// Error Handling:
/// - Throws [RepositoryException] for database/encryption failures
/// - Throws [EntityNotFoundException] when requested entity doesn't exist
/// - Returns null from getCategory() if not found (for optional lookups)
class CategoryRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Category';

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
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> createCategory(ui.Category category) async {
    try {
      final data = _toData(category);
      final encryptedBlob = await encryptionService.encryptCategory(data);

      await database.insertCategory(
        id: category.id,
        sortOrder: category.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Create or update a category (encrypt and upsert)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> upsertCategory(ui.Category category) async {
    try {
      final data = _toData(category);
      final encryptedBlob = await encryptionService.encryptCategory(data);

      await database.upsertCategory(
        id: category.id,
        sortOrder: category.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Get a single category by ID (fetch, decrypt, verify)
  ///
  /// Returns null if category doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Category?> getCategory(String id) async {
    final row = await database.getCategory(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decryptCategory(
        row.encryptedBlob,
        expectedId: row.id,
        expectedSortOrder: row.sortOrder,
      );
      return _toCategory(data);
    } catch (e) {
      throw RepositoryException.decryption(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Get a single category by ID, throwing if not found.
  ///
  /// Throws [EntityNotFoundException] if category doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Category> getCategoryOrThrow(String id) async {
    final category = await getCategory(id);
    if (category == null) {
      throw EntityNotFoundException(entityType: _entityType, entityId: id);
    }
    return category;
  }

  /// Get all non-deleted categories
  ///
  /// Throws [RepositoryException] if fetch or decryption fails.
  Future<List<ui.Category>> getAllCategories() async {
    try {
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
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  /// Update an existing category (re-encrypt and update)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> updateCategory(ui.Category category) async {
    try {
      final data = _toData(category);
      final encryptedBlob = await encryptionService.encryptCategory(data);

      await database.updateCategory(
        id: category.id,
        sortOrder: category.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: category.id,
        cause: e,
      );
    }
  }

  /// Soft delete a category (set isDeleted = true)
  ///
  /// Throws [RepositoryException] if database operation fails.
  Future<void> deleteCategory(String id) async {
    try {
      await database.softDeleteCategory(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Watch all categories (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  /// Corrupted rows are silently skipped to maintain stream stability.
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
          // Skip corrupted rows in stream to maintain stability
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
  ///
  /// Throws [RepositoryException] if any category fails to seed.
  Future<void> seedDefaultCategories() async {
    final defaults = ui.DefaultCategories.all;
    for (final category in defaults) {
      await upsertCategory(category);
    }
  }
}
