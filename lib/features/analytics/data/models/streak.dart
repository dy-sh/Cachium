enum StreakType {
  noSpend,
  underBudget,
  savings,
  dailyLogging,
}

extension StreakTypeExtension on StreakType {
  String get displayName {
    switch (this) {
      case StreakType.noSpend:
        return 'No-Spend Days';
      case StreakType.underBudget:
        return 'Under Budget';
      case StreakType.savings:
        return 'Saving Streak';
      case StreakType.dailyLogging:
        return 'Daily Logging';
    }
  }

  String get description {
    switch (this) {
      case StreakType.noSpend:
        return 'Days without spending';
      case StreakType.underBudget:
        return 'Days spending under daily average';
      case StreakType.savings:
        return 'Consecutive days with positive balance';
      case StreakType.dailyLogging:
        return 'Days with at least one transaction logged';
    }
  }
}

class Streak {
  final StreakType type;
  final int currentCount;
  final int bestCount;
  final DateTime? startDate;
  final bool isActive;

  const Streak({
    required this.type,
    required this.currentCount,
    required this.bestCount,
    this.startDate,
    this.isActive = true,
  });

  double get progress => bestCount > 0 ? currentCount / bestCount : 0;
}
