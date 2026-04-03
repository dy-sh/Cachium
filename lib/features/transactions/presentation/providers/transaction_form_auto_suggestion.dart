import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'transaction_form_provider.dart';
import 'transactions_provider.dart';

mixin TransactionAutoSuggestion
    on AutoDisposeNotifier<TransactionFormState> {
  void autoCategorizeByMerchant(String merchant) {
    final autoEnabled = ref.read(autoCategorizeByMerchantProvider);
    if (!autoEnabled) return;

    // Only auto-fill if no manual category was selected
    if (state.categoryId == null || state.categoryAutoSelected) {
      final merchantMap = ref.read(merchantCategoryMapProvider);
      final suggestedCategoryId = merchantMap[merchant.trim().toLowerCase()];
      if (suggestedCategoryId != null) {
        final category = ref.read(categoryByIdProvider(suggestedCategoryId));
        if (category != null) {
          state = state.copyWith(
            categoryId: suggestedCategoryId,
            categoryAutoSelected: true,
          );
        }
      }
    }
  }

  void autoSuggestAsset() {
    if (state.isEditing) return;
    // Don't override manual asset selection
    if (state.assetId != null && !state.assetAutoSelected) return;

    final suggested = ref.read(suggestedAssetProvider((
      merchant: state.merchant,
      categoryId: state.categoryId,
    )));

    if (suggested != null) {
      state = state.copyWith(assetId: suggested, assetAutoSelected: true);
    } else if (state.assetAutoSelected) {
      // Clear auto-suggested asset when suggestion no longer applies
      state = state.copyWith(clearAssetId: true, assetAutoSelected: false);
    }
  }
}
