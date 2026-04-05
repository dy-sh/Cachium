import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/assets/data/models/asset.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

Asset _makeAsset({
  String id = 'asset-1',
  String name = 'Test Asset',
  IconData icon = Icons.star,
  int colorIndex = 0,
  AssetStatus status = AssetStatus.active,
  DateTime? soldDate,
  double? salePrice,
  String? saleCurrencyCode,
  String? note,
  double? purchasePrice,
  String? purchaseCurrencyCode,
  String? assetCategoryId,
  DateTime? purchaseDate,
  int sortOrder = 0,
  DateTime? createdAt,
}) {
  return Asset(
    id: id,
    name: name,
    icon: icon,
    colorIndex: colorIndex,
    status: status,
    soldDate: soldDate,
    salePrice: salePrice,
    saleCurrencyCode: saleCurrencyCode,
    note: note,
    purchasePrice: purchasePrice,
    purchaseCurrencyCode: purchaseCurrencyCode,
    assetCategoryId: assetCategoryId,
    purchaseDate: purchaseDate,
    sortOrder: sortOrder,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('Asset.validate()', () {
    test('accepts valid asset', () {
      expect(() => _makeAsset().validate(), returnsNormally);
    });

    test('rejects empty id', () {
      expect(
        () => _makeAsset(id: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => _makeAsset(name: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative colorIndex', () {
      expect(
        () => _makeAsset(colorIndex: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative purchasePrice', () {
      expect(
        () => _makeAsset(purchasePrice: -100.0).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative salePrice', () {
      expect(
        () => _makeAsset(salePrice: -50.0).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative sortOrder', () {
      expect(
        () => _makeAsset(sortOrder: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts null prices', () {
      expect(() => _makeAsset().validate(), returnsNormally);
    });

    test('accepts zero prices', () {
      expect(
        () => _makeAsset(purchasePrice: 0.0, salePrice: 0.0).validate(),
        returnsNormally,
      );
    });
  });

  group('Asset equality', () {
    test('assets with same id are equal', () {
      final a1 = _makeAsset(id: 'abc', name: 'A');
      final a2 = _makeAsset(id: 'abc', name: 'B');
      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('assets with different ids are not equal', () {
      final a1 = _makeAsset(id: 'abc');
      final a2 = _makeAsset(id: 'def');
      expect(a1, isNot(equals(a2)));
    });
  });

  group('Asset.copyWith()', () {
    test('updates specified fields', () {
      final asset = _makeAsset(name: 'Old');
      final copy = asset.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.id, asset.id);
    });

    test('clearSoldDate sets to null', () {
      final asset = _makeAsset(soldDate: DateTime(2026, 6, 1));
      final copy = asset.copyWith(clearSoldDate: true);
      expect(copy.soldDate, isNull);
    });

    test('clearSalePrice sets to null', () {
      final asset = _makeAsset(salePrice: 500.0);
      final copy = asset.copyWith(clearSalePrice: true);
      expect(copy.salePrice, isNull);
    });

    test('clearSaleCurrencyCode sets to null', () {
      final asset = _makeAsset(saleCurrencyCode: 'EUR');
      final copy = asset.copyWith(clearSaleCurrencyCode: true);
      expect(copy.saleCurrencyCode, isNull);
    });

    test('clearNote sets to null', () {
      final asset = _makeAsset(note: 'Some note');
      final copy = asset.copyWith(clearNote: true);
      expect(copy.note, isNull);
    });

    test('clearPurchasePrice sets to null', () {
      final asset = _makeAsset(purchasePrice: 1000.0);
      final copy = asset.copyWith(clearPurchasePrice: true);
      expect(copy.purchasePrice, isNull);
    });

    test('clearPurchaseCurrencyCode sets to null', () {
      final asset = _makeAsset(purchaseCurrencyCode: 'USD');
      final copy = asset.copyWith(clearPurchaseCurrencyCode: true);
      expect(copy.purchaseCurrencyCode, isNull);
    });

    test('clearAssetCategoryId sets to null', () {
      final asset = _makeAsset(assetCategoryId: 'cat-1');
      final copy = asset.copyWith(clearAssetCategoryId: true);
      expect(copy.assetCategoryId, isNull);
    });

    test('clearPurchaseDate sets to null', () {
      final asset = _makeAsset(purchaseDate: DateTime(2025, 1, 1));
      final copy = asset.copyWith(clearPurchaseDate: true);
      expect(copy.purchaseDate, isNull);
    });
  });

  group('AssetStatus extension', () {
    test('displayName returns correct values', () {
      expect(AssetStatus.active.displayName, 'Active');
      expect(AssetStatus.sold.displayName, 'Sold');
    });
  });
}
