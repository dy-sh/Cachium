import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
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
    _IconEntry(LucideIcons.shoppingCart, 'shopping cart buy store'),
    _IconEntry(LucideIcons.utensils, 'utensils food dining restaurant'),
    _IconEntry(LucideIcons.car, 'car vehicle drive transport'),
    _IconEntry(LucideIcons.home, 'home house rent mortgage'),
    _IconEntry(LucideIcons.plane, 'plane flight travel airport'),
    _IconEntry(LucideIcons.heartPulse, 'health medical hospital doctor'),
    _IconEntry(LucideIcons.graduationCap, 'education school university study'),
    _IconEntry(LucideIcons.gamepad2, 'gaming game play entertainment'),
    _IconEntry(LucideIcons.music, 'music song audio sound'),
    _IconEntry(LucideIcons.film, 'film movie cinema video'),
    _IconEntry(LucideIcons.gift, 'gift present birthday party'),
    _IconEntry(LucideIcons.coffee, 'coffee cafe drink beverage'),
    _IconEntry(LucideIcons.beer, 'beer drink alcohol bar'),
    _IconEntry(LucideIcons.pizza, 'pizza fast food delivery'),
    _IconEntry(LucideIcons.dumbbell, 'gym fitness workout exercise'),
    _IconEntry(LucideIcons.shirt, 'clothing shirt fashion apparel'),
    _IconEntry(LucideIcons.scissors, 'scissors haircut salon beauty'),
    _IconEntry(LucideIcons.smartphone, 'phone mobile device tech'),
    _IconEntry(LucideIcons.laptop, 'laptop computer tech device'),
    _IconEntry(LucideIcons.wifi, 'wifi internet network bill'),
    _IconEntry(LucideIcons.zap, 'electricity power energy utility'),
    _IconEntry(LucideIcons.droplets, 'water utility bill plumbing'),
    _IconEntry(LucideIcons.flame, 'gas heating fire utility'),
    _IconEntry(LucideIcons.dog, 'dog pet animal veterinary'),
    _IconEntry(LucideIcons.cat, 'cat pet animal veterinary'),
    _IconEntry(LucideIcons.baby, 'baby child kids family'),
    _IconEntry(LucideIcons.users, 'family people group social'),
    _IconEntry(LucideIcons.briefcase, 'work job office business'),
    _IconEntry(LucideIcons.wallet, 'wallet money cash payment'),
    _IconEntry(LucideIcons.receipt, 'receipt bill invoice payment'),
    _IconEntry(LucideIcons.creditCard, 'credit card payment bank'),
    _IconEntry(LucideIcons.piggyBank, 'savings piggy bank money'),
    _IconEntry(LucideIcons.trendingUp, 'investment profit growth stocks'),
    _IconEntry(LucideIcons.trendingDown, 'loss decline decrease expense'),
    _IconEntry(LucideIcons.dollarSign, 'money dollar salary income'),
    _IconEntry(LucideIcons.percent, 'percent discount sale offer'),
    _IconEntry(LucideIcons.tag, 'tag label price sale'),
    _IconEntry(LucideIcons.star, 'star favorite special premium'),
    _IconEntry(LucideIcons.heart, 'heart love favorite charity'),
    _IconEntry(LucideIcons.smile, 'happy smile face emoji'),
    _IconEntry(LucideIcons.sun, 'sun weather outdoor summer'),
    _IconEntry(LucideIcons.moon, 'moon night sleep evening'),
    _IconEntry(LucideIcons.umbrella, 'umbrella rain weather insurance'),
    _IconEntry(LucideIcons.snowflake, 'snow winter cold season'),
    _IconEntry(LucideIcons.leaf, 'nature leaf plant garden'),
    _IconEntry(LucideIcons.flower2, 'flower garden nature plant'),
    _IconEntry(LucideIcons.bike, 'bike bicycle cycling sport'),
    _IconEntry(LucideIcons.bus, 'bus transit public transport'),
    _IconEntry(LucideIcons.train, 'train rail transit commute'),
    _IconEntry(LucideIcons.ship, 'ship boat cruise ferry'),
    _IconEntry(LucideIcons.building, 'building office apartment rent'),
    _IconEntry(LucideIcons.store, 'store shop merchant retail'),
    _IconEntry(LucideIcons.school, 'school education tuition class'),
    _IconEntry(LucideIcons.church, 'church religion donation tithe'),
    _IconEntry(LucideIcons.activity, 'activity health sport fitness'),
    _IconEntry(LucideIcons.bookOpen, 'book reading education library'),
    _IconEntry(LucideIcons.sparkles, 'sparkle clean beauty cosmetic'),
    _IconEntry(LucideIcons.gem, 'gem jewelry luxury accessory'),
    _IconEntry(LucideIcons.crown, 'crown premium vip luxury'),
    _IconEntry(LucideIcons.moreHorizontal, 'more other miscellaneous general'),
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
            borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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
