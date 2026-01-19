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
  static const Color cyan = Color(0xFF5BBCD9);
  static const Color skyBlue = Color(0xFF7BA3C9);
  static const Color cornflower = Color(0xFF8B9DC9);
  static const Color royalBlue = Color(0xFF6B8BC9);
  static const Color dodgerBlue = Color(0xFF5B9BC9);
  static const Color deepSkyBlue = Color(0xFF5BB5C9);
  static const Color green = Color(0xFF5BC98B);
  static const Color lightGreen = Color(0xFF8BC98B);
  static const Color red = Color(0xFFC97B7B);
  static const Color salmon = Color(0xFFC98B8B);
  static const Color yellow = Color(0xFFC9B95B);
  static const Color lightGold = Color(0xFFC9C07B);
  static const Color purple = Color(0xFFA68BC9);
  static const Color lightPurple = Color(0xFF9B7BC9);
  static const Color orange = Color(0xFFC9955B);
  static const Color lightOrange = Color(0xFFC9A06B);
  static const Color pink = Color(0xFFC97BA6);
  static const Color lightPink = Color(0xFFC98BB5);

  // Prism versions (vivid)
  static const Color cyanPrism = Color(0xFF33CCEE);
  static const Color skyBluePrism = Color(0xFF5599EE);
  static const Color cornflowerPrism = Color(0xFF6688EE);
  static const Color royalBluePrism = Color(0xFF5577EE);
  static const Color dodgerBluePrism = Color(0xFF4499EE);
  static const Color deepSkyBluePrism = Color(0xFF33BBDD);
  static const Color greenPrism = Color(0xFF33DD99);
  static const Color lightGreenPrism = Color(0xFF88DD88);
  static const Color redPrism = Color(0xFFEE5555);
  static const Color salmonPrism = Color(0xFFEE7777);
  static const Color yellowPrism = Color(0xFFEECC55);
  static const Color lightGoldPrism = Color(0xFFEEDD66);
  static const Color purplePrism = Color(0xFFAA77DD);
  static const Color lightPurplePrism = Color(0xFF9977DD);
  static const Color orangePrism = Color(0xFFDD9955);
  static const Color lightOrangePrism = Color(0xFFDDAA66);
  static const Color pinkPrism = Color(0xFFDD66BB);
  static const Color lightPinkPrism = Color(0xFFDD77CC);

  // Pastel versions (soft, light, calming)
  static const Color cyanPastel = Color(0xFFA8E6F0);
  static const Color skyBluePastel = Color(0xFFB8D4F0);
  static const Color cornflowerPastel = Color(0xFFC5CCF0);
  static const Color royalBluePastel = Color(0xFFB0C4F0);
  static const Color dodgerBluePastel = Color(0xFFA8D0F0);
  static const Color deepSkyBluePastel = Color(0xFFA0DCF0);
  static const Color greenPastel = Color(0xFF98E8B8);
  static const Color lightGreenPastel = Color(0xFFB8F0B8);
  static const Color redPastel = Color(0xFFF0B8B8);
  static const Color salmonPastel = Color(0xFFF0C8C8);
  static const Color yellowPastel = Color(0xFFF0E8A8);
  static const Color lightGoldPastel = Color(0xFFF0ECB8);
  static const Color purplePastel = Color(0xFFD8C8F0);
  static const Color lightPurplePastel = Color(0xFFD0BFF0);
  static const Color orangePastel = Color(0xFFF0D0A8);
  static const Color lightOrangePastel = Color(0xFFF0D8B8);
  static const Color pinkPastel = Color(0xFFF0B8D8);
  static const Color lightPinkPastel = Color(0xFFF0C8E0);

  // Neon versions (ultra-saturated, electric)
  static const Color cyanNeon = Color(0xFF00FFFF);
  static const Color skyBlueNeon = Color(0xFF00BFFF);
  static const Color cornflowerNeon = Color(0xFF6495ED);
  static const Color royalBlueNeon = Color(0xFF4169E1);
  static const Color dodgerBlueNeon = Color(0xFF1E90FF);
  static const Color deepSkyBlueNeon = Color(0xFF00CED1);
  static const Color greenNeon = Color(0xFF39FF14);
  static const Color lightGreenNeon = Color(0xFF7FFF00);
  static const Color redNeon = Color(0xFFFF073A);
  static const Color salmonNeon = Color(0xFFFF6B6B);
  static const Color yellowNeon = Color(0xFFFFFF00);
  static const Color lightGoldNeon = Color(0xFFFFD700);
  static const Color purpleNeon = Color(0xFFBF00FF);
  static const Color lightPurpleNeon = Color(0xFF9400D3);
  static const Color orangeNeon = Color(0xFFFF6600);
  static const Color lightOrangeNeon = Color(0xFFFF8C00);
  static const Color pinkNeon = Color(0xFFFF1493);
  static const Color lightPinkNeon = Color(0xFFFF69B4);

  // Vintage versions (retro, warm, nostalgic)
  static const Color cyanVintage = Color(0xFF45B5AA);
  static const Color skyBlueVintage = Color(0xFF6B9AC4);
  static const Color cornflowerVintage = Color(0xFF8884C4);
  static const Color royalBlueVintage = Color(0xFF5B6FAF);
  static const Color dodgerBlueVintage = Color(0xFF5890B5);
  static const Color deepSkyBlueVintage = Color(0xFF4AA8A8);
  static const Color greenVintage = Color(0xFF7CB472);
  static const Color lightGreenVintage = Color(0xFF9CB46B);
  static const Color redVintage = Color(0xFFCF6B6B);
  static const Color salmonVintage = Color(0xFFE8927C);
  static const Color yellowVintage = Color(0xFFD4A84B);
  static const Color lightGoldVintage = Color(0xFFE8C55D);
  static const Color purpleVintage = Color(0xFF9678B4);
  static const Color lightPurpleVintage = Color(0xFFAA8DC4);
  static const Color orangeVintage = Color(0xFFD98545);
  static const Color lightOrangeVintage = Color(0xFFE89F5C);
  static const Color pinkVintage = Color(0xFFD4789B);
  static const Color lightPinkVintage = Color(0xFFE895B0);

  // Accent color options - Zen (the preferred set)
  static const List<Color> accentOptionsZen = [
    Color(0xFFFFFFFF), // White (default)
    cyan, skyBlue, cornflower, royalBlue, dodgerBlue, deepSkyBlue,
    green, lightGreen, red, salmon, yellow, lightGold,
    purple, lightPurple, orange, lightOrange, pink, lightPink,
  ];

  // Accent color options - Prism (more saturated)
  static const List<Color> accentOptionsPrism = [
    Color(0xFFFFFFFF), // White (default)
    cyanPrism, skyBluePrism, cornflowerPrism, royalBluePrism, dodgerBluePrism, deepSkyBluePrism,
    greenPrism, lightGreenPrism, redPrism, salmonPrism, yellowPrism, lightGoldPrism,
    purplePrism, lightPurplePrism, orangePrism, lightOrangePrism, pinkPrism, lightPinkPrism,
  ];

  // Accent color options - Pastel (soft, light)
  static const List<Color> accentOptionsPastel = [
    Color(0xFFFFFFFF), // White (default)
    cyanPastel, skyBluePastel, cornflowerPastel, royalBluePastel, dodgerBluePastel, deepSkyBluePastel,
    greenPastel, lightGreenPastel, redPastel, salmonPastel, yellowPastel, lightGoldPastel,
    purplePastel, lightPurplePastel, orangePastel, lightOrangePastel, pinkPastel, lightPinkPastel,
  ];

  // Accent color options - Neon (ultra-saturated)
  static const List<Color> accentOptionsNeon = [
    Color(0xFFFFFFFF), // White (default)
    cyanNeon, skyBlueNeon, cornflowerNeon, royalBlueNeon, dodgerBlueNeon, deepSkyBlueNeon,
    greenNeon, lightGreenNeon, redNeon, salmonNeon, yellowNeon, lightGoldNeon,
    purpleNeon, lightPurpleNeon, orangeNeon, lightOrangeNeon, pinkNeon, lightPinkNeon,
  ];

  // Accent color options - Vintage (retro, warm)
  static const List<Color> accentOptionsVintage = [
    Color(0xFFFFFFFF), // White (default)
    cyanVintage, skyBlueVintage, cornflowerVintage, royalBlueVintage, dodgerBlueVintage, deepSkyBlueVintage,
    greenVintage, lightGreenVintage, redVintage, salmonVintage, yellowVintage, lightGoldVintage,
    purpleVintage, lightPurpleVintage, orangeVintage, lightOrangeVintage, pinkVintage, lightPinkVintage,
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
      case ColorIntensity.pastel:
        return accentOptionsPastel;
      case ColorIntensity.neon:
        return accentOptionsNeon;
      case ColorIntensity.vintage:
        return accentOptionsVintage;
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

  static const Color accountBankPastel = cyanPastel;
  static const Color accountCreditCardPastel = redPastel;
  static const Color accountCashPastel = greenPastel;
  static const Color accountSavingsPastel = yellowPastel;
  static const Color accountInvestmentPastel = purplePastel;
  static const Color accountWalletPastel = orangePastel;

  static const Color accountBankNeon = cyanNeon;
  static const Color accountCreditCardNeon = redNeon;
  static const Color accountCashNeon = greenNeon;
  static const Color accountSavingsNeon = yellowNeon;
  static const Color accountInvestmentNeon = purpleNeon;
  static const Color accountWalletNeon = orangeNeon;

  static const Color accountBankVintage = cyanVintage;
  static const Color accountCreditCardVintage = redVintage;
  static const Color accountCashVintage = greenVintage;
  static const Color accountSavingsVintage = yellowVintage;
  static const Color accountInvestmentVintage = purpleVintage;
  static const Color accountWalletVintage = orangeVintage;

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
  static const Color incomePastel = greenPastel;
  static const Color expensePastel = redPastel;
  static const Color incomeNeon = greenNeon;
  static const Color expenseNeon = redNeon;
  static const Color incomeVintage = greenVintage;
  static const Color expenseVintage = redVintage;

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

  // Category colors - pastel (soft, light)
  static const List<Color> categoryColorsPastel = [
    cyanPastel, skyBluePastel, cornflowerPastel, royalBluePastel, dodgerBluePastel, deepSkyBluePastel,
    greenPastel, lightGreenPastel, redPastel, salmonPastel, yellowPastel, lightGoldPastel,
    purplePastel, lightPurplePastel, orangePastel, lightOrangePastel, pinkPastel, lightPinkPastel,
  ];

  // Category colors - neon (ultra-saturated)
  static const List<Color> categoryColorsNeon = [
    cyanNeon, skyBlueNeon, cornflowerNeon, royalBlueNeon, dodgerBlueNeon, deepSkyBlueNeon,
    greenNeon, lightGreenNeon, redNeon, salmonNeon, yellowNeon, lightGoldNeon,
    purpleNeon, lightPurpleNeon, orangeNeon, lightOrangeNeon, pinkNeon, lightPinkNeon,
  ];

  // Category colors - vintage (retro, warm)
  static const List<Color> categoryColorsVintage = [
    cyanVintage, skyBlueVintage, cornflowerVintage, royalBlueVintage, dodgerBlueVintage, deepSkyBlueVintage,
    greenVintage, lightGreenVintage, redVintage, salmonVintage, yellowVintage, lightGoldVintage,
    purpleVintage, lightPurpleVintage, orangeVintage, lightOrangeVintage, pinkVintage, lightPinkVintage,
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
      case ColorIntensity.pastel:
        return categoryColorsPastel;
      case ColorIntensity.neon:
        return categoryColorsNeon;
      case ColorIntensity.vintage:
        return categoryColorsVintage;
    }
  }

  // Get account color by type with intensity support
  static Color getAccountColor(String type, [ColorIntensity intensity = ColorIntensity.prism]) {
    switch (type) {
      case 'bank':
        return _getColorForIntensity(accountBankZen, accountBankPrism, accountBankPastel, accountBankNeon, accountBankVintage, intensity);
      case 'creditCard':
        return _getColorForIntensity(accountCreditCardZen, accountCreditCardPrism, accountCreditCardPastel, accountCreditCardNeon, accountCreditCardVintage, intensity);
      case 'cash':
        return _getColorForIntensity(accountCashZen, accountCashPrism, accountCashPastel, accountCashNeon, accountCashVintage, intensity);
      case 'savings':
        return _getColorForIntensity(accountSavingsZen, accountSavingsPrism, accountSavingsPastel, accountSavingsNeon, accountSavingsVintage, intensity);
      case 'investment':
        return _getColorForIntensity(accountInvestmentZen, accountInvestmentPrism, accountInvestmentPastel, accountInvestmentNeon, accountInvestmentVintage, intensity);
      case 'wallet':
        return _getColorForIntensity(accountWalletZen, accountWalletPrism, accountWalletPastel, accountWalletNeon, accountWalletVintage, intensity);
      default:
        return _getColorForIntensity(accountBankZen, accountBankPrism, accountBankPastel, accountBankNeon, accountBankVintage, intensity);
    }
  }

  static Color _getColorForIntensity(Color dim, Color bright, Color pastel, Color neon, Color vintage, ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return bright;
      case ColorIntensity.zen:
        return dim;
      case ColorIntensity.pastel:
        return pastel;
      case ColorIntensity.neon:
        return neon;
      case ColorIntensity.vintage:
        return vintage;
    }
  }

  // Get transaction color by type with intensity support
  static Color getTransactionColor(String type, [ColorIntensity intensity = ColorIntensity.prism]) {
    switch (type) {
      case 'income':
        return _getColorForIntensity(incomeZen, incomePrism, incomePastel, incomeNeon, incomeVintage, intensity);
      case 'expense':
        return _getColorForIntensity(expenseZen, expensePrism, expensePastel, expenseNeon, expenseVintage, intensity);
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
      case ColorIntensity.pastel:
        return 0.25;
      case ColorIntensity.zen:
        return 0.20;
      case ColorIntensity.vintage:
        return 0.25;
    }
  }

  // Get border opacity appropriate for each palette
  static double getBorderOpacity(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.prism:
        return 0.5;
      case ColorIntensity.neon:
        return 1.0;
      case ColorIntensity.pastel:
      case ColorIntensity.vintage:
        return 0.8;
      case ColorIntensity.zen:
        return 0.6;
    }
  }

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
