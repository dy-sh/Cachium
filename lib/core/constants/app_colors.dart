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

  // Base color palette (dim - muted and darker)
  static const Color cyan = Color(0xFF0086A2);
  static const Color skyBlue = Color(0xFF3169A2);
  static const Color cornflower = Color(0xFF4459A2);
  static const Color royalBlue = Color(0xFF2041A2);
  static const Color dodgerBlue = Color(0xFF135CA2);
  static const Color deepSkyBlue = Color(0xFF007AA2);
  static const Color green = Color(0xFF00A257);
  static const Color lightGreen = Color(0xFF4FA24F);
  static const Color red = Color(0xFFA24444);
  static const Color salmon = Color(0xFFA25454);
  static const Color yellow = Color(0xFFA28D31);
  static const Color lightGold = Color(0xFFA28E41);
  static const Color purple = Color(0xFF7A61A2);
  static const Color lightPurple = Color(0xFF7257A2);
  static const Color orange = Color(0xFFA26311);
  static const Color lightOrange = Color(0xFFA26E20);
  static const Color pink = Color(0xFFA24272);
  static const Color lightPink = Color(0xFFA25480);

  // Bright versions (vivid)
  static const Color cyanBright = Color(0xFF00D4FF);
  static const Color skyBlueBright = Color(0xFF4DA6FF);
  static const Color cornflowerBright = Color(0xFF6B8CFF);
  static const Color royalBlueBright = Color(0xFF3366FF);
  static const Color dodgerBlueBright = Color(0xFF1E90FF);
  static const Color deepSkyBlueBright = Color(0xFF00BFFF);
  static const Color greenBright = Color(0xFF00FF88);
  static const Color lightGreenBright = Color(0xFF7CFF7C);
  static const Color redBright = Color(0xFFFF6B6B);
  static const Color salmonBright = Color(0xFFFF8585);
  static const Color yellowBright = Color(0xFFFFDD4D);
  static const Color lightGoldBright = Color(0xFFFFE066);
  static const Color purpleBright = Color(0xFFC098FF);
  static const Color lightPurpleBright = Color(0xFFB388FF);
  static const Color orangeBright = Color(0xFFFF9D1A);
  static const Color lightOrangeBright = Color(0xFFFFAD33);
  static const Color pinkBright = Color(0xFFFF69B4);
  static const Color lightPinkBright = Color(0xFFFF85C8);

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

  // Earth versions (natural, warm-toned)
  static const Color cyanEarth = Color(0xFF5B8A8A);
  static const Color skyBlueEarth = Color(0xFF5F7A8A);
  static const Color cornflowerEarth = Color(0xFF6B7A8A);
  static const Color royalBlueEarth = Color(0xFF4A6A8A);
  static const Color dodgerBlueEarth = Color(0xFF4A7A8A);
  static const Color deepSkyBlueEarth = Color(0xFF4A8A8A);
  static const Color greenEarth = Color(0xFF6B8E6B);
  static const Color lightGreenEarth = Color(0xFF8B9E6B);
  static const Color redEarth = Color(0xFF8E6B6B);
  static const Color salmonEarth = Color(0xFF9E7B7B);
  static const Color yellowEarth = Color(0xFF9E946B);
  static const Color lightGoldEarth = Color(0xFFA89E6B);
  static const Color purpleEarth = Color(0xFF7B6B8E);
  static const Color lightPurpleEarth = Color(0xFF8B7B9E);
  static const Color orangeEarth = Color(0xFF9E7B5B);
  static const Color lightOrangeEarth = Color(0xFFA88B6B);
  static const Color pinkEarth = Color(0xFF8E6B7B);
  static const Color lightPinkEarth = Color(0xFF9E7B8B);

  // Accent color options - Dim (the preferred set)
  static const List<Color> accentOptionsDim = [
    Color(0xFFFFFFFF), // White (default)
    cyan, skyBlue, cornflower, royalBlue, dodgerBlue, deepSkyBlue,
    green, lightGreen, red, salmon, yellow, lightGold,
    purple, lightPurple, orange, lightOrange, pink, lightPink,
  ];

  // Accent color options - Bright (more saturated)
  static const List<Color> accentOptionsBright = [
    Color(0xFFFFFFFF), // White (default)
    cyanBright, skyBlueBright, cornflowerBright, royalBlueBright, dodgerBlueBright, deepSkyBlueBright,
    greenBright, lightGreenBright, redBright, salmonBright, yellowBright, lightGoldBright,
    purpleBright, lightPurpleBright, orangeBright, lightOrangeBright, pinkBright, lightPinkBright,
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

  // Accent color options - Earth (natural, warm)
  static const List<Color> accentOptionsEarth = [
    Color(0xFFFFFFFF), // White (default)
    cyanEarth, skyBlueEarth, cornflowerEarth, royalBlueEarth, dodgerBlueEarth, deepSkyBlueEarth,
    greenEarth, lightGreenEarth, redEarth, salmonEarth, yellowEarth, lightGoldEarth,
    purpleEarth, lightPurpleEarth, orangeEarth, lightOrangeEarth, pinkEarth, lightPinkEarth,
  ];

  // Legacy accessor
  static const List<Color> accentOptions = accentOptionsDim;

  // Get accent options based on intensity
  static List<Color> getAccentOptions(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.bright:
        return accentOptionsBright;
      case ColorIntensity.dim:
        return accentOptionsDim;
      case ColorIntensity.pastel:
        return accentOptionsPastel;
      case ColorIntensity.neon:
        return accentOptionsNeon;
      case ColorIntensity.earth:
        return accentOptionsEarth;
    }
  }

  // Get specific accent color by index with intensity
  static Color getAccentColor(int index, ColorIntensity intensity) {
    final options = getAccentOptions(intensity);
    return options[index.clamp(0, options.length - 1)];
  }

  // Account type colors - using base palette
  static const Color accountBankDim = cyan;
  static const Color accountCreditCardDim = red;
  static const Color accountCashDim = green;
  static const Color accountSavingsDim = yellow;
  static const Color accountInvestmentDim = purple;
  static const Color accountWalletDim = orange;

  static const Color accountBankBright = cyanBright;
  static const Color accountCreditCardBright = redBright;
  static const Color accountCashBright = greenBright;
  static const Color accountSavingsBright = yellowBright;
  static const Color accountInvestmentBright = purpleBright;
  static const Color accountWalletBright = orangeBright;

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

  static const Color accountBankEarth = cyanEarth;
  static const Color accountCreditCardEarth = redEarth;
  static const Color accountCashEarth = greenEarth;
  static const Color accountSavingsEarth = yellowEarth;
  static const Color accountInvestmentEarth = purpleEarth;
  static const Color accountWalletEarth = orangeEarth;

  // Legacy accessors (use dim by default)
  static const Color accountBank = accountBankDim;
  static const Color accountCreditCard = accountCreditCardDim;
  static const Color accountCash = accountCashDim;
  static const Color accountSavings = accountSavingsDim;
  static const Color accountInvestment = accountInvestmentDim;
  static const Color accountWallet = accountWalletDim;

  // Semantic colors - using base palette
  static const Color incomeDim = green;
  static const Color expenseDim = red;
  static const Color incomeBright = greenBright;
  static const Color expenseBright = redBright;
  static const Color incomePastel = greenPastel;
  static const Color expensePastel = redPastel;
  static const Color incomeNeon = greenNeon;
  static const Color expenseNeon = redNeon;
  static const Color incomeEarth = greenEarth;
  static const Color expenseEarth = redEarth;

  // Legacy semantic colors (dim by default)
  static const Color income = incomeDim;
  static const Color expense = expenseDim;

  // Navigation colors
  static const Color navActive = Color(0xFFFFFFFF);
  static const Color navInactive = Color(0xFF5A5A5A);

  // Category colors - dim (base palette)
  static const List<Color> categoryColorsDim = [
    cyan, skyBlue, green, lightGreen, red, salmon,
    yellow, purple, lightPurple, orange, pink, lightPink,
  ];

  // Category colors - bright (more saturated)
  static const List<Color> categoryColorsBright = [
    cyanBright, skyBlueBright, greenBright, lightGreenBright, redBright, salmonBright,
    yellowBright, purpleBright, lightPurpleBright, orangeBright, pinkBright, lightPinkBright,
  ];

  // Category colors - pastel (soft, light)
  static const List<Color> categoryColorsPastel = [
    cyanPastel, skyBluePastel, greenPastel, lightGreenPastel, redPastel, salmonPastel,
    yellowPastel, purplePastel, lightPurplePastel, orangePastel, pinkPastel, lightPinkPastel,
  ];

  // Category colors - neon (ultra-saturated)
  static const List<Color> categoryColorsNeon = [
    cyanNeon, skyBlueNeon, greenNeon, lightGreenNeon, redNeon, salmonNeon,
    yellowNeon, purpleNeon, lightPurpleNeon, orangeNeon, pinkNeon, lightPinkNeon,
  ];

  // Category colors - earth (natural, warm)
  static const List<Color> categoryColorsEarth = [
    cyanEarth, skyBlueEarth, greenEarth, lightGreenEarth, redEarth, salmonEarth,
    yellowEarth, purpleEarth, lightPurpleEarth, orangeEarth, pinkEarth, lightPinkEarth,
  ];

  // Legacy accessor
  static const List<Color> categoryColors = categoryColorsDim;

  // Get category colors based on intensity
  static List<Color> getCategoryColors(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.bright:
        return categoryColorsBright;
      case ColorIntensity.dim:
        return categoryColorsDim;
      case ColorIntensity.pastel:
        return categoryColorsPastel;
      case ColorIntensity.neon:
        return categoryColorsNeon;
      case ColorIntensity.earth:
        return categoryColorsEarth;
    }
  }

  // Get account color by type with intensity support
  static Color getAccountColor(String type, [ColorIntensity intensity = ColorIntensity.bright]) {
    switch (type) {
      case 'bank':
        return _getColorForIntensity(accountBankDim, accountBankBright, accountBankPastel, accountBankNeon, accountBankEarth, intensity);
      case 'creditCard':
        return _getColorForIntensity(accountCreditCardDim, accountCreditCardBright, accountCreditCardPastel, accountCreditCardNeon, accountCreditCardEarth, intensity);
      case 'cash':
        return _getColorForIntensity(accountCashDim, accountCashBright, accountCashPastel, accountCashNeon, accountCashEarth, intensity);
      case 'savings':
        return _getColorForIntensity(accountSavingsDim, accountSavingsBright, accountSavingsPastel, accountSavingsNeon, accountSavingsEarth, intensity);
      case 'investment':
        return _getColorForIntensity(accountInvestmentDim, accountInvestmentBright, accountInvestmentPastel, accountInvestmentNeon, accountInvestmentEarth, intensity);
      case 'wallet':
        return _getColorForIntensity(accountWalletDim, accountWalletBright, accountWalletPastel, accountWalletNeon, accountWalletEarth, intensity);
      default:
        return _getColorForIntensity(accountBankDim, accountBankBright, accountBankPastel, accountBankNeon, accountBankEarth, intensity);
    }
  }

  static Color _getColorForIntensity(Color dim, Color bright, Color pastel, Color neon, Color earth, ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.bright:
        return bright;
      case ColorIntensity.dim:
        return dim;
      case ColorIntensity.pastel:
        return pastel;
      case ColorIntensity.neon:
        return neon;
      case ColorIntensity.earth:
        return earth;
    }
  }

  // Get transaction color by type with intensity support
  static Color getTransactionColor(String type, [ColorIntensity intensity = ColorIntensity.bright]) {
    switch (type) {
      case 'income':
        return _getColorForIntensity(incomeDim, incomeBright, incomePastel, incomeNeon, incomeEarth, intensity);
      case 'expense':
        return _getColorForIntensity(expenseDim, expenseBright, expensePastel, expenseNeon, expenseEarth, intensity);
      default:
        return textPrimary;
    }
  }

  // Get background opacity appropriate for each palette
  static double getBgOpacity(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.bright:
        return 0.35;
      case ColorIntensity.neon:
        return 0.40;
      case ColorIntensity.pastel:
        return 0.25;
      case ColorIntensity.dim:
        return 0.15;
      case ColorIntensity.earth:
        return 0.20;
    }
  }

  // Get border opacity appropriate for each palette
  static double getBorderOpacity(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.bright:
      case ColorIntensity.neon:
        return 1.0;
      case ColorIntensity.pastel:
        return 0.8;
      case ColorIntensity.dim:
      case ColorIntensity.earth:
        return 0.5;
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
