import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class IconPickerGrid extends StatefulWidget {
  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData>? onIconSelected;

  const IconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    this.onIconSelected,
  });

  static final List<_IconEntry> _iconEntries = [
    const _IconEntry(LucideIcons.shoppingCart, 'shopping cart buy store'),
    const _IconEntry(LucideIcons.utensils, 'utensils food dining restaurant'),
    const _IconEntry(LucideIcons.car, 'car vehicle drive transport'),
    const _IconEntry(LucideIcons.home, 'home house rent mortgage'),
    const _IconEntry(LucideIcons.plane, 'plane flight travel airport'),
    const _IconEntry(LucideIcons.heartPulse, 'health medical hospital doctor'),
    const _IconEntry(LucideIcons.graduationCap, 'education school university study'),
    const _IconEntry(LucideIcons.gamepad2, 'gaming game play entertainment'),
    const _IconEntry(LucideIcons.music, 'music song audio sound'),
    const _IconEntry(LucideIcons.film, 'film movie cinema video'),
    const _IconEntry(LucideIcons.gift, 'gift present birthday party'),
    const _IconEntry(LucideIcons.coffee, 'coffee cafe drink beverage'),
    const _IconEntry(LucideIcons.beer, 'beer drink alcohol bar'),
    const _IconEntry(LucideIcons.pizza, 'pizza fast food delivery'),
    const _IconEntry(LucideIcons.dumbbell, 'gym fitness workout exercise'),
    const _IconEntry(LucideIcons.shirt, 'clothing shirt fashion apparel'),
    const _IconEntry(LucideIcons.scissors, 'scissors haircut salon beauty'),
    const _IconEntry(LucideIcons.smartphone, 'phone mobile device tech'),
    const _IconEntry(LucideIcons.laptop, 'laptop computer tech device'),
    const _IconEntry(LucideIcons.wifi, 'wifi internet network bill'),
    const _IconEntry(LucideIcons.zap, 'electricity power energy utility'),
    const _IconEntry(LucideIcons.droplets, 'water utility bill plumbing'),
    const _IconEntry(LucideIcons.flame, 'gas heating fire utility'),
    const _IconEntry(LucideIcons.dog, 'dog pet animal veterinary'),
    const _IconEntry(LucideIcons.cat, 'cat pet animal veterinary'),
    const _IconEntry(LucideIcons.baby, 'baby child kids family'),
    const _IconEntry(LucideIcons.users, 'family people group social'),
    const _IconEntry(LucideIcons.briefcase, 'work job office business'),
    const _IconEntry(LucideIcons.wallet, 'wallet money cash payment'),
    const _IconEntry(LucideIcons.receipt, 'receipt bill invoice payment'),
    const _IconEntry(LucideIcons.creditCard, 'credit card payment bank'),
    const _IconEntry(LucideIcons.piggyBank, 'savings piggy bank money'),
    const _IconEntry(LucideIcons.trendingUp, 'investment profit growth stocks'),
    const _IconEntry(LucideIcons.trendingDown, 'loss decline decrease expense'),
    const _IconEntry(LucideIcons.dollarSign, 'money dollar salary income'),
    const _IconEntry(LucideIcons.percent, 'percent discount sale offer'),
    const _IconEntry(LucideIcons.tag, 'tag label price sale'),
    const _IconEntry(LucideIcons.star, 'star favorite special premium'),
    const _IconEntry(LucideIcons.heart, 'heart love favorite charity'),
    const _IconEntry(LucideIcons.smile, 'happy smile face emoji'),
    const _IconEntry(LucideIcons.sun, 'sun weather outdoor summer'),
    const _IconEntry(LucideIcons.moon, 'moon night sleep evening'),
    const _IconEntry(LucideIcons.umbrella, 'umbrella rain weather insurance'),
    const _IconEntry(LucideIcons.snowflake, 'snow winter cold season'),
    const _IconEntry(LucideIcons.leaf, 'nature leaf plant garden'),
    const _IconEntry(LucideIcons.flower2, 'flower garden nature plant'),
    const _IconEntry(LucideIcons.bike, 'bike bicycle cycling sport'),
    const _IconEntry(LucideIcons.bus, 'bus transit public transport'),
    const _IconEntry(LucideIcons.train, 'train rail transit commute'),
    const _IconEntry(LucideIcons.ship, 'ship boat cruise ferry'),
    const _IconEntry(LucideIcons.building, 'building office apartment rent'),
    const _IconEntry(LucideIcons.store, 'store shop merchant retail'),
    const _IconEntry(LucideIcons.school, 'school education tuition class'),
    const _IconEntry(LucideIcons.church, 'church religion donation tithe'),
    const _IconEntry(LucideIcons.activity, 'activity health sport fitness'),
    const _IconEntry(LucideIcons.bookOpen, 'book reading education library'),
    const _IconEntry(LucideIcons.sparkles, 'sparkle clean beauty cosmetic'),
    const _IconEntry(LucideIcons.gem, 'gem jewelry luxury accessory'),
    const _IconEntry(LucideIcons.crown, 'crown premium vip luxury'),
    const _IconEntry(LucideIcons.moreHorizontal, 'more other miscellaneous general'),
  ];

  static List<IconData> get availableIcons =>
      _iconEntries.map((e) => e.icon).toList();

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconEntry {
  final IconData icon;
  final String keywords;

  const _IconEntry(this.icon, this.keywords);
}

class _IconPickerGridState extends State<IconPickerGrid> {
  String _searchQuery = '';

  List<IconData> get _filteredIcons {
    if (_searchQuery.isEmpty) return IconPickerGrid.availableIcons;
    final query = _searchQuery.toLowerCase();
    return IconPickerGrid._iconEntries
        .where((e) => e.keywords.contains(query))
        .map((e) => e.icon)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _filteredIcons;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: AppTypography.bodySmall,
            cursorColor: widget.selectedColor,
            decoration: InputDecoration(
              hintText: 'Search icons...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                size: 16,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (icons.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'No icons found',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              final isSelected = icon == widget.selectedIcon;
              return GestureDetector(
                onTap: widget.onIconSelected != null
                    ? () => widget.onIconSelected!(icon)
                    : null,
                child: AnimatedContainer(
                  duration: AppAnimations.normal,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.selectedColor.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: isSelected ? widget.selectedColor : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? widget.selectedColor
                        : AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
