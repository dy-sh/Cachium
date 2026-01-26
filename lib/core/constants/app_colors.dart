import 'package:flutter/material.dart';
import '../../features/settings/data/models/app_settings.dart';

class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceLight = Color(0xFF121212);

  // Border colors
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderSelected = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textTertiary = Color(0xFF5A5A5A);

  // Accent colors
  static const Color accentPrimary = Color(0xFFFFFFFF);
  static const Color selectionGlow = Color(0x33FFFFFF); // 20% opacity white

  // Base color palette (zen - softer, muted but visible)
  // 23 distinct colors evenly spaced 15° apart on the color wheel
  static const Color red = Color(0xFFD47B7B);           // 0° - red
  static const Color vermilion = Color(0xFFD4897B);     // 15° - red-orange
  static const Color orange = Color(0xFFD49F7B);        // 30° - orange
  static const Color amber = Color(0xFFD4B57B);         // 45° - amber
  static const Color yellow = Color(0xFFD4CA7B);        // 60° - yellow
  static const Color chartreuse = Color(0xFFC2D47B);    // 75° - yellow-green
  static const Color lime = Color(0xFFA5D47B);          // 90° - lime
  static const Color harlequin = Color(0xFF89D47B);     // 105° - spring
  static const Color green = Color(0xFF7BD48A);         // 120° - green
  static const Color emerald = Color(0xFF7BD4A6);       // 135° - emerald
  static const Color jade = Color(0xFF7BD4C2);          // 150° - jade
  static const Color aquamarine = Color(0xFF7BD4D4);    // 165° - aquamarine
  static const Color cyan = Color(0xFF7BC2D4);          // 180° - cyan
  static const Color sky = Color(0xFF7BA6D4);           // 195° - sky
  static const Color azure = Color(0xFF7B8AD4);         // 210° - azure
  static const Color cerulean = Color(0xFF7B7BD4);      // 225° - cerulean
  static const Color blue = Color(0xFF8A7BD4);          // 240° - blue
  static const Color indigo = Color(0xFFA67BD4);        // 255° - indigo
  static const Color violet = Color(0xFFC27BD4);        // 270° - violet
  static const Color purple = Color(0xFFD47BD4);        // 285° - purple
  static const Color magenta = Color(0xFFD47BC2);       // 300° - magenta
  static const Color fuchsia = Color(0xFFD47BA6);       // 315° - fuchsia
  static const Color rose = Color(0xFFD47B8A);          // 330° - rose
  static const Color pink = Color(0xFFD47B7B);          // 345° - pink (wraps to red-ish)
  // Legacy aliases for compatibility
  static const Color coral = vermilion;
  static const Color gold = amber;
  static const Color teal = jade;
  static const Color skyBlue = sky;
  static const Color cornflower = cerulean;
  static const Color royalBlue = blue;
  static const Color dodgerBlue = azure;
  static const Color deepSkyBlue = cyan;
  static const Color lightGreen = lime;
  static const Color salmon = vermilion;
  static const Color lightGold = amber;
  static const Color lightPurple = violet;
  static const Color lightOrange = vermilion;
  static const Color lightPink = rose;

  // Prism versions (vivid) - 23 distinct colors at 15° spacing
  static const Color redPrism = Color(0xFFE64545);           // 0°
  static const Color vermilionPrism = Color(0xFFE66345);     // 15°
  static const Color orangePrism = Color(0xFFE68A45);        // 30°
  static const Color amberPrism = Color(0xFFE6B145);         // 45°
  static const Color yellowPrism = Color(0xFFE6D845);        // 60°
  static const Color chartreusePrism = Color(0xFFC2E645);    // 75°
  static const Color limePrism = Color(0xFF8AE645);          // 90°
  static const Color harlequinPrism = Color(0xFF52E645);     // 105°
  static const Color greenPrism = Color(0xFF45E663);         // 120°
  static const Color emeraldPrism = Color(0xFF45E69B);       // 135°
  static const Color jadePrism = Color(0xFF45E6C2);          // 150°
  static const Color aquamarinePrism = Color(0xFF45E6E6);    // 165°
  static const Color cyanPrism = Color(0xFF45C2E6);          // 180°
  static const Color skyPrism = Color(0xFF459BE6);           // 195°
  static const Color azurePrism = Color(0xFF4563E6);         // 210°
  static const Color ceruleanPrism = Color(0xFF4545E6);      // 225°
  static const Color bluePrism = Color(0xFF6345E6);          // 240°
  static const Color indigoPrism = Color(0xFF9B45E6);        // 255°
  static const Color violetPrism = Color(0xFFC245E6);        // 270°
  static const Color purplePrism = Color(0xFFE645E6);        // 285°
  static const Color magentaPrism = Color(0xFFE645C2);       // 300°
  static const Color fuchsiaPrism = Color(0xFFE6459B);       // 315°
  static const Color rosePrism = Color(0xFFE64563);          // 330°
  static const Color pinkPrism = Color(0xFFE64552);          // 345°
  // Legacy aliases
  static const Color coralPrism = vermilionPrism;
  static const Color goldPrism = amberPrism;
  static const Color tealPrism = jadePrism;
  static const Color skyBluePrism = skyPrism;
  static const Color cornflowerPrism = ceruleanPrism;
  static const Color royalBluePrism = bluePrism;
  static const Color dodgerBluePrism = azurePrism;
  static const Color deepSkyBluePrism = cyanPrism;
  static const Color lightGreenPrism = limePrism;
  static const Color salmonPrism = vermilionPrism;
  static const Color lightGoldPrism = amberPrism;
  static const Color lightPurplePrism = violetPrism;
  static const Color lightOrangePrism = vermilionPrism;
  static const Color lightPinkPrism = rosePrism;

  // Neon versions (ultra-saturated, electric) - 23 distinct colors at 15° spacing
  static const Color redNeon = Color(0xFFFF0000);            // 0°
  static const Color vermilionNeon = Color(0xFFFF4000);      // 15°
  static const Color orangeNeon = Color(0xFFFF8000);         // 30°
  static const Color amberNeon = Color(0xFFFFBF00);          // 45°
  static const Color yellowNeon = Color(0xFFFFFF00);         // 60°
  static const Color chartreuseNeon = Color(0xFFBFFF00);     // 75°
  static const Color limeNeon = Color(0xFF80FF00);           // 90°
  static const Color harlequinNeon = Color(0xFF40FF00);      // 105°
  static const Color greenNeon = Color(0xFF00FF40);          // 120°
  static const Color emeraldNeon = Color(0xFF00FF80);        // 135°
  static const Color jadeNeon = Color(0xFF00FFBF);           // 150°
  static const Color aquamarineNeon = Color(0xFF00FFFF);     // 165°
  static const Color cyanNeon = Color(0xFF00BFFF);           // 180°
  static const Color skyNeon = Color(0xFF0080FF);            // 195°
  static const Color azureNeon = Color(0xFF0040FF);          // 210°
  static const Color ceruleanNeon = Color(0xFF0000FF);       // 225°
  static const Color blueNeon = Color(0xFF4000FF);           // 240°
  static const Color indigoNeon = Color(0xFF8000FF);         // 255°
  static const Color violetNeon = Color(0xFFBF00FF);         // 270°
  static const Color purpleNeon = Color(0xFFFF00FF);         // 285°
  static const Color magentaNeon = Color(0xFFFF00BF);        // 300°
  static const Color fuchsiaNeon = Color(0xFFFF0080);        // 315°
  static const Color roseNeon = Color(0xFFFF0040);           // 330°
  static const Color pinkNeon = Color(0xFFFF0020);           // 345°
  // Legacy aliases
  static const Color coralNeon = vermilionNeon;
  static const Color goldNeon = amberNeon;
  static const Color tealNeon = jadeNeon;
  static const Color skyBlueNeon = skyNeon;
  static const Color cornflowerNeon = ceruleanNeon;
  static const Color royalBlueNeon = blueNeon;
  static const Color dodgerBlueNeon = azureNeon;
  static const Color deepSkyBlueNeon = cyanNeon;
  static const Color lightGreenNeon = limeNeon;
  static const Color salmonNeon = vermilionNeon;
  static const Color lightGoldNeon = amberNeon;
  static const Color lightPurpleNeon = violetNeon;
  static const Color lightOrangeNeon = vermilionNeon;
  static const Color lightPinkNeon = roseNeon;


  // Accent color options - Zen (24 colors: white + 23 colors at 15° spacing)
  static const List<Color> accentOptionsZen = [
    Color(0xFFFFFFFF), // 0: White (default)
    red,          // 1: 0°
    vermilion,    // 2: 15°
    orange,       // 3: 30°
    amber,        // 4: 45°
    yellow,       // 5: 60°
    chartreuse,   // 6: 75°
    lime,         // 7: 90°
    harlequin,    // 8: 105°
    green,        // 9: 120°
    emerald,      // 10: 135°
    jade,         // 11: 150°
    aquamarine,   // 12: 165°
    cyan,         // 13: 180°
    sky,          // 14: 195°
    azure,        // 15: 210°
    cerulean,     // 16: 225°
    blue,         // 17: 240°
    indigo,       // 18: 255°
    violet,       // 19: 270°
    purple,       // 20: 285°
    magenta,      // 21: 300°
    fuchsia,      // 22: 315°
    rose,         // 23: 330°
  ];

  // Accent color options - Prism (more saturated)
  static const List<Color> accentOptionsPrism = [
    Color(0xFFFFFFFF),
    redPrism, vermilionPrism, orangePrism, amberPrism, yellowPrism, chartreusePrism,
    limePrism, harlequinPrism, greenPrism, emeraldPrism, jadePrism, aquamarinePrism,
    cyanPrism, skyPrism, azurePrism, ceruleanPrism, bluePrism, indigoPrism,
    violetPrism, purplePrism, magentaPrism, fuchsiaPrism, rosePrism,
  ];

  // Accent color options - Neon (ultra-saturated)
  static const List<Color> accentOptionsNeon = [
    Color(0xFFFFFFFF),
    redNeon, vermilionNeon, orangeNeon, amberNeon, yellowNeon, chartreuseNeon,
    limeNeon, harlequinNeon, greenNeon, emeraldNeon, jadeNeon, aquamarineNeon,
    cyanNeon, skyNeon, azureNeon, ceruleanNeon, blueNeon, indigoNeon,
    violetNeon, purpleNeon, magentaNeon, fuchsiaNeon, roseNeon,
  ];


  // Legacy accessor
  static const List<Color> accentOptions = accentOptionsZen;

  // Get accent options based on intensity
  static List<Color> getAccentOptions(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return accentOptionsPrism;
      case ColorIntensity.zen:
        return accentOptionsZen;
      case ColorIntensity.neon:
        return accentOptionsNeon;
    }
  }

  // Get specific accent color by index with intensity
  static Color getAccentColor(int index, ColorIntensity intensity) {
    final options = getAccentOptions(intensity);
    return options[index.clamp(0, options.length - 1)];
  }

  // Account type colors - using base palette
  static const Color accountBankZen = cyan;
  static const Color accountCreditCardZen = red;
  static const Color accountCashZen = green;
  static const Color accountSavingsZen = yellow;
  static const Color accountInvestmentZen = purple;
  static const Color accountWalletZen = orange;

  static const Color accountBankPrism = cyanPrism;
  static const Color accountCreditCardPrism = redPrism;
  static const Color accountCashPrism = greenPrism;
  static const Color accountSavingsPrism = yellowPrism;
  static const Color accountInvestmentPrism = purplePrism;
  static const Color accountWalletPrism = orangePrism;

  static const Color accountBankNeon = cyanNeon;
  static const Color accountCreditCardNeon = redNeon;
  static const Color accountCashNeon = greenNeon;
  static const Color accountSavingsNeon = yellowNeon;
  static const Color accountInvestmentNeon = purpleNeon;
  static const Color accountWalletNeon = orangeNeon;

  // Legacy accessors (use dim by default)
  static const Color accountBank = accountBankZen;
  static const Color accountCreditCard = accountCreditCardZen;
  static const Color accountCash = accountCashZen;
  static const Color accountSavings = accountSavingsZen;
  static const Color accountInvestment = accountInvestmentZen;
  static const Color accountWallet = accountWalletZen;

  // Semantic colors - using base palette
  static const Color incomeZen = green;
  static const Color expenseZen = red;
  static const Color incomePrism = greenPrism;
  static const Color expensePrism = redPrism;
  static const Color incomeNeon = greenNeon;
  static const Color expenseNeon = redNeon;

  // Legacy semantic colors (dim by default)
  static const Color income = incomeZen;
  static const Color expense = expenseZen;

  // Navigation colors
  static const Color navActive = Color(0xFFFFFFFF);
  static const Color navInactive = Color(0xFF5A5A5A);

  // Category colors - dim (base palette) - 18 colors matching accent options
  static const List<Color> categoryColorsZen = [
    cyan, skyBlue, cornflower, royalBlue, dodgerBlue, deepSkyBlue,
    green, lightGreen, red, salmon, yellow, lightGold,
    purple, lightPurple, orange, lightOrange, pink, lightPink,
  ];

  // Category colors - bright (more saturated)
  static const List<Color> categoryColorsPrism = [
    cyanPrism, skyBluePrism, cornflowerPrism, royalBluePrism, dodgerBluePrism, deepSkyBluePrism,
    greenPrism, lightGreenPrism, redPrism, salmonPrism, yellowPrism, lightGoldPrism,
    purplePrism, lightPurplePrism, orangePrism, lightOrangePrism, pinkPrism, lightPinkPrism,
  ];

  // Category colors - neon (ultra-saturated)
  static const List<Color> categoryColorsNeon = [
    cyanNeon, skyBlueNeon, cornflowerNeon, royalBlueNeon, dodgerBlueNeon, deepSkyBlueNeon,
    greenNeon, lightGreenNeon, redNeon, salmonNeon, yellowNeon, lightGoldNeon,
    purpleNeon, lightPurpleNeon, orangeNeon, lightOrangeNeon, pinkNeon, lightPinkNeon,
  ];

  // Legacy accessor
  static const List<Color> categoryColors = categoryColorsZen;

  // Get category colors based on intensity
  static List<Color> getCategoryColors(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return categoryColorsPrism;
      case ColorIntensity.zen:
        return categoryColorsZen;
      case ColorIntensity.neon:
        return categoryColorsNeon;
    }
  }

  // Get account color by type with intensity support
  static Color getAccountColor(String type, [ColorIntensity intensity = ColorIntensity.prism]) {
    switch (type) {
      case 'bank':
        return _getColorForIntensity(accountBankZen, accountBankPrism, accountBankNeon, intensity);
      case 'creditCard':
        return _getColorForIntensity(accountCreditCardZen, accountCreditCardPrism, accountCreditCardNeon, intensity);
      case 'cash':
        return _getColorForIntensity(accountCashZen, accountCashPrism, accountCashNeon, intensity);
      case 'savings':
        return _getColorForIntensity(accountSavingsZen, accountSavingsPrism, accountSavingsNeon, intensity);
      case 'investment':
        return _getColorForIntensity(accountInvestmentZen, accountInvestmentPrism, accountInvestmentNeon, intensity);
      case 'wallet':
        return _getColorForIntensity(accountWalletZen, accountWalletPrism, accountWalletNeon, intensity);
      default:
        return _getColorForIntensity(accountBankZen, accountBankPrism, accountBankNeon, intensity);
    }
  }

  static Color _getColorForIntensity(Color zen, Color prism, Color neon, ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return prism;
      case ColorIntensity.zen:
        return zen;
      case ColorIntensity.neon:
        return neon;
    }
  }

  // Get transaction color by type with intensity support
  static Color getTransactionColor(String type, [ColorIntensity intensity = ColorIntensity.prism]) {
    switch (type) {
      case 'income':
        return _getColorForIntensity(incomeZen, incomePrism, incomeNeon, intensity);
      case 'expense':
        return _getColorForIntensity(expenseZen, expensePrism, expenseNeon, intensity);
      default:
        return textPrimary;
    }
  }

  // Get background opacity appropriate for each palette
  static double getBgOpacity(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return 0.35;
      case ColorIntensity.neon:
        return 0.40;
      case ColorIntensity.zen:
        return 0.20;
    }
  }

  // Get border opacity appropriate for each palette
  static double getBorderOpacity(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return 0.5;
      case ColorIntensity.neon:
        return 1.0;
      case ColorIntensity.zen:
        return 0.6;
    }
  }

  // ==========================================================================
  // CSV Import Mapping Colors
  // ==========================================================================
  // Unified color system for CSV field mapping. Uses indices from the
  // 24-color accent palette. Special fields have semantic colors matching
  // transaction/account colors for consistency.

  /// Color indices for special mapping fields (from accent palette)
  static const int mappingAmountIndex = 9;      // Green - matches income/cash
  static const int mappingCategoryIndex = 13;   // Cyan - matches bank account
  static const int mappingAccountIndex = 3;     // Orange - matches wallet account

  /// Regular field color sequence - 20 distinct colors for position-based assignment.
  /// Maximizes visual separation between consecutive items.
  /// Reserved indices NOT in this list: 9 (amount/green), 13 (category/cyan), 3 (orange/account), 0 (white), 1 (red/expense)
  static const List<int> mappingFieldColorIndices = [
    7,   // Lime
    19,  // Violet
    5,   // Yellow
    12,  // Aquamarine
    22,  // Fuchsia
    17,  // Blue
    10,  // Emerald
    23,  // Rose
    4,   // Amber
    14,  // Sky
    8,   // Harlequin
    21,  // Magenta
    6,   // Chartreuse
    18,  // Indigo
    11,  // Jade
    20,  // Purple
    2,   // Vermilion
    16,  // Cerulean
    15,  // Azure
  ];

  /// Get mapping color for Amount field.
  static Color getMappingAmountColor(ColorIntensity intensity) {
    return getAccentColor(mappingAmountIndex, intensity);
  }

  /// Get mapping color for Category FK field.
  static Color getMappingCategoryColor(ColorIntensity intensity) {
    return getAccentColor(mappingCategoryIndex, intensity);
  }

  /// Get mapping color for Account FK field.
  static Color getMappingAccountColor(ColorIntensity intensity) {
    return getAccentColor(mappingAccountIndex, intensity);
  }

  /// Get mapping color for a foreign key type ('category' or 'account').
  static Color getMappingForeignKeyColor(String foreignKey, ColorIntensity intensity) {
    return foreignKey == 'category'
        ? getMappingCategoryColor(intensity)
        : getMappingAccountColor(intensity);
  }

  /// Get mapping color for a regular field by its position index (1-based).
  /// Returns a color from the distinct field color palette.
  static Color getMappingFieldColor(int fieldIndex, ColorIntensity intensity) {
    final colorIndex = mappingFieldColorIndices[
        (fieldIndex - 1) % mappingFieldColorIndices.length];
    return getAccentColor(colorIndex, intensity);
  }

  /// Get mapping color for a field by its position index.
  /// Colors are purely position-based for consistency across all entity types.
  static Color getMappingFieldColorByKey(
    String fieldKey,
    int fieldIndex,
    ColorIntensity intensity,
  ) {
    // Pure position-based colors - same position = same color across all entity types
    return getMappingFieldColor(fieldIndex, intensity);
  }

  // ==========================================================================

  // Utility methods for color variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
