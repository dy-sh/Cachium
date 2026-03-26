import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../data/models/asset.dart';
import '../providers/assets_provider.dart';
import '../widgets/asset_form_modal.dart';

/// Opens the asset edit modal with standard save/delete/duplicate behavior.
///
/// [onDeleted] is called after the asset is deleted (e.g., to pop the detail screen).
/// [onDuplicated] is called with the new asset ID after duplication.
void openAssetEditModal(
  BuildContext context,
  WidgetRef ref,
  Asset asset, {
  VoidCallback? onDeleted,
  void Function(String newId)? onDuplicated,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (modalContext) => AssetFormModal(
        asset: asset,
        onSave: (result) async {
          final updatedAsset = asset.copyWith(
            name: result.name,
            icon: result.icon,
            colorIndex: result.colorIndex,
            status: result.status,
            note: result.note,
            clearNote: result.note == null,
            purchasePrice: result.purchasePrice,
            clearPurchasePrice: result.purchasePrice == null,
            purchaseCurrencyCode: result.purchaseCurrencyCode,
            clearPurchaseCurrencyCode: result.purchaseCurrencyCode == null,
            assetCategoryId: result.assetCategoryId,
            clearAssetCategoryId: result.assetCategoryId == null,
            purchaseDate: result.purchaseDate,
            clearPurchaseDate: result.purchaseDate == null,
          );
          await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);
          if (modalContext.mounted) {
            Navigator.of(modalContext).pop();
            context.showSuccessNotification('Asset updated');
          }
        },
        onDelete: () async {
          await ref.read(assetsProvider.notifier).deleteAsset(asset.id);
          if (modalContext.mounted) {
            Navigator.of(modalContext).pop();
            context.showSuccessNotification('Asset deleted');
            onDeleted?.call();
          }
        },
        onDuplicate: (sourceAsset) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (dupContext) => AssetFormModal(
                asset: Asset(
                  id: '',
                  name: '${sourceAsset.name} (Copy)',
                  icon: sourceAsset.icon,
                  colorIndex: sourceAsset.colorIndex,
                  note: sourceAsset.note,
                  purchasePrice: sourceAsset.purchasePrice,
                  purchaseCurrencyCode: sourceAsset.purchaseCurrencyCode,
                  assetCategoryId: sourceAsset.assetCategoryId,
                  purchaseDate: null,
                  sortOrder: 0,
                  createdAt: DateTime.now(),
                ),
                onSave: (result) async {
                  final newId = await ref.read(assetsProvider.notifier).addAsset(
                    name: result.name,
                    icon: result.icon,
                    colorIndex: result.colorIndex,
                    note: result.note,
                    purchasePrice: result.purchasePrice,
                    purchaseCurrencyCode: result.purchaseCurrencyCode,
                    assetCategoryId: result.assetCategoryId,
                    purchaseDate: result.purchaseDate,
                  );
                  if (dupContext.mounted) {
                    Navigator.of(dupContext).pop();
                    context.showSuccessNotification('Asset duplicated');
                    onDuplicated?.call(newId);
                  }
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}
