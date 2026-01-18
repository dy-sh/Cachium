class AppSpacing {
  AppSpacing._();

  // Base unit: 4px
  static const double unit = 4.0;

  // Spacing scale
  static const double xs = 4.0;   // 1 unit
  static const double sm = 8.0;   // 2 units
  static const double md = 12.0;  // 3 units
  static const double lg = 16.0;  // 4 units
  static const double xl = 20.0;  // 5 units
  static const double xxl = 24.0; // 6 units
  static const double xxxl = 32.0; // 8 units

  // Component-specific spacing (reduced by 10-15% for compact layout)
  static const double cardPadding = 10.0;
  static const double screenPadding = 14.0;
  static const double sectionGap = 20.0;
  static const double itemGap = 10.0;
  static const double chipGap = 6.0;

  // Compact chip padding for tighter layouts
  static const double chipPaddingHorizontalCompact = 10.0;
  static const double chipPaddingVerticalCompact = 6.0;

  // Navigation
  static const double bottomNavHeight = 52.0;
  static const double bottomNavPadding = 4.0;

  // Input
  static const double inputPadding = 10.0;
  static const double inputHeight = 48.0;

  // Button
  static const double buttonHeight = 48.0;
  static const double buttonPadding = 14.0;
  static const double iconButtonSize = 40.0;

  // List items (reduced for compact layout)
  static const double listItemHeight = 58.0;
  static const double listItemPadding = 10.0;

  // Calendar
  static const double calendarDayCellSize = 40.0;
  static const double calendarRowSpacing = 4.0;
  static const double calendarGridHeight = 264.0; // 6 rows * (40px + 4px)
  static const double calendarHeaderButtonSize = 36.0;
  static const int calendarGridCellCount = 42; // 6 rows * 7 days

  // Close/Action buttons
  static const double closeButtonSize = 40.0;
}
