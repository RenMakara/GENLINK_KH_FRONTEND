import 'package:flutter/material.dart';

import '../shadows/app_shadows.dart';

abstract final class AppColors {


  static const lightBgPrimary = Color(0xFFF7F8FA);      
  static const lightBgSecondary = Color(0xFFF0F2F5);   

  static const lightSurfacePrimary = Color(0xFFFFFFFF); 
  static const lightSurfaceSecondary = Color(0xFFFFFFFF);
  static const lightSurfaceGlass = Color.fromRGBO(255, 255, 255, 0.85);

  static const lightTextPrimary = Color(0xFF18191B);    
  static const lightTextSecondary = Color(0xFF5C6066);
  static const lightTextMuted = Color(0xFF8C9199);
  static const lightTextInverse = Color(0xFFFFFFFF);

  static const lightBorderSubtle = Color(0xFFE5E7EB);
  static const lightBorderStrong = Color(0xFFD1D5DB);

  static const lightPrimary = Color(0xFF18191B);
  static const lightPrimarySoft = Color(0xFFF0F2F5);


  static const darkBgPrimary = Color(0xFF18191A);
  static const darkBgSecondary = Color(0xFF1E1F20);

  static const darkSurfacePrimary = Color(0xFF242526);
  static const darkSurfaceSecondary = Color(0xFF2A2B2D);
  static const darkSurfaceGlass = Color.fromRGBO(36, 37, 38, 0.78);

  static const darkTextPrimary = Color(0xFFE4E6EB);
  static const darkTextSecondary = Color(0xFFB0B3B8);
  static const darkTextMuted = Color(0xFF8A8D91);
  static const darkTextInverse = Color(0xFF18191A);






  static const darkBorderSubtle = Color(0xFF323436);
  static const darkBorderStrong = Color(0xFF3E4042);

  static const darkPrimary = Color(0xFFE4E6EB);
  static const darkPrimarySoft = Color(0xFF2A2B2D);


  static const accentPremium = Color(0xFFC8BFAE);

  static const likedAccent = Color(0xFFFF1640);
  static const likePink = Color(0xFFFF1640);

  static const danger = Color(
    0xFFE41414,
  );
  static const success = Color(
    0xFF22C55E,
  );
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFFA0A0A0);

  static const brandPrimary = Color(0xFF1F6FEB);
  static const communityAccent = Color(0xFF5DADEC);
  static const productivityAccent = Color(0xFF8B7CF6);
  static const financeAccent = Color(0xFF4BAE73);
  static const growthAccent = Color(0xFFF2B84B);
  static const profileAccent = Color(0xFFC8BFAE);

  // Chat Design System Brand Tokens (Aligined with current GenLink application primary brand: 0xFF1F6FEB)
  static const chatPrimary = brandPrimary; // Color(0xFF1F6FEB)
  static const chatPrimaryDark = Color(0xFF1659C7);
  static const chatPrimaryLight = Color(0xFF388BFD);
  static const chatPrimarySoft = Color(0x1F1F6FEB);
  static const chatPrimaryBubble = brandPrimary;


  static const navBgLight = Color(0xEAFFFFFF);
  static const navBorderLight = Color(0x1F000000);
  static const navActiveSurfaceLight = Color(0x12000000);
  static const navActiveIconLight = Color(0xFF18191B);
  static const navActiveLabelLight = Color(0xFF18191B);
  static const navInactiveIconLight = Color(0xFF71767B);
  static const navInactiveLabelLight = Color(0xFF71767B);
  static const navCreateBgLight = Color(0xFF18191B);
  static const navCreateIconLight = Color(0xFFFFFFFF);

  static const navBgDark = Color(0xEE1E1F21);
  static const navBorderDark = Color(0x29FFFFFF);
  static const navActiveSurfaceDark = Color(0x24FFFFFF);
  static const navActiveIconDark = Color(0xFFFFFFFF);
  static const navActiveLabelDark = Color(0xFFFFFFFF);
  static const navInactiveIconDark = Color(0xFF8E9297);
  static const navInactiveLabelDark = Color(0xFF8E9297);
  static const navCreateBgDark = Color(0xFF383A3D);
  static const navCreateIconDark = Color(0xFFFFFFFF);


  static AppSemanticColors of(BuildContext context) =>
      AppSemanticColors.of(context);

  static AppSemanticColors forBrightness(Brightness brightness) =>
      AppSemanticColors.forBrightness(brightness);
}

class AppSemanticColors {
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color borderStrong;
  final Color primaryText;
  final Color secondaryText;
  final Color textMuted;
  final Color textInverse;
  final Color primary;
  final Color primarySoft;
  final Color navigationSurface;
  final Color navigationBorder;
  final Color navigationActiveSurface;
  final Color navigationActiveIcon;
  final Color navigationActiveLabel;
  final Color navigationInactiveIcon;
  final Color navigationInactiveLabel;
  final Color navigationCreateBg;
  final Color navigationCreateIcon;
  final Color tabActiveBg;
  final Color tabActiveText;
  final Color tabInactiveBg;
  final Color tabInactiveText;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> navigationShadow;

  const AppSemanticColors({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderStrong,
    required this.primaryText,
    required this.secondaryText,
    required this.textMuted,
    required this.textInverse,
    required this.primary,
    required this.primarySoft,
    required this.navigationSurface,
    required this.navigationBorder,
    required this.navigationActiveSurface,
    required this.navigationActiveIcon,
    required this.navigationActiveLabel,
    required this.navigationInactiveIcon,
    required this.navigationInactiveLabel,
    required this.navigationCreateBg,
    required this.navigationCreateIcon,
    required this.tabActiveBg,
    required this.tabActiveText,
    required this.tabInactiveBg,
    required this.tabInactiveText,
    required this.cardShadow,
    required this.navigationShadow,
  });

  static const light = AppSemanticColors(
    background: AppColors.lightBgPrimary,
    backgroundSecondary: AppColors.lightBgSecondary,
    surface: AppColors.lightSurfacePrimary,
    surfaceElevated: AppColors.lightSurfaceSecondary,
    borderSubtle: AppColors.lightBorderSubtle,
    borderStrong: AppColors.lightBorderStrong,
    primaryText: AppColors.lightTextPrimary,
    secondaryText: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    textInverse: AppColors.lightTextInverse,
    primary: AppColors.lightPrimary,
    primarySoft: AppColors.lightPrimarySoft,
    navigationSurface: AppColors.navBgLight,
    navigationBorder: AppColors.navBorderLight,
    navigationActiveSurface: AppColors.navActiveSurfaceLight,
    navigationActiveIcon: AppColors.navActiveIconLight,
    navigationActiveLabel: AppColors.navActiveLabelLight,
    navigationInactiveIcon: AppColors.navInactiveIconLight,
    navigationInactiveLabel: AppColors.navInactiveLabelLight,
    navigationCreateBg: AppColors.navCreateBgLight,
    navigationCreateIcon: AppColors.navCreateIconLight,
    tabActiveBg: AppColors.lightPrimary,
    tabActiveText: AppColors.lightTextInverse,
    tabInactiveBg: AppColors.lightSurfacePrimary,
    tabInactiveText: AppColors.lightTextSecondary,
    cardShadow: AppShadows.cardLight,
    navigationShadow: AppShadows.navLight,
  );

  static const dark = AppSemanticColors(
    background: AppColors.darkBgPrimary,
    backgroundSecondary: AppColors.darkBgSecondary,
    surface: AppColors.darkSurfacePrimary,
    surfaceElevated: AppColors.darkSurfaceSecondary,
    borderSubtle: AppColors.darkBorderSubtle,
    borderStrong: AppColors.darkBorderStrong,
    primaryText: AppColors.darkTextPrimary,
    secondaryText: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    textInverse: AppColors.darkTextInverse,
    primary: AppColors.darkPrimary,
    primarySoft: AppColors.darkPrimarySoft,
    navigationSurface: AppColors.navBgDark,
    navigationBorder: AppColors.navBorderDark,
    navigationActiveSurface: AppColors.navActiveSurfaceDark,
    navigationActiveIcon: AppColors.navActiveIconDark,
    navigationActiveLabel: AppColors.navActiveLabelDark,
    navigationInactiveIcon: AppColors.navInactiveIconDark,
    navigationInactiveLabel: AppColors.navInactiveLabelDark,
    navigationCreateBg: AppColors.navCreateBgDark,
    navigationCreateIcon: AppColors.navCreateIconDark,
    tabActiveBg: AppColors.darkPrimary,
    tabActiveText: AppColors.darkTextInverse,
    tabInactiveBg: AppColors.darkSurfacePrimary,
    tabInactiveText: AppColors.darkTextSecondary,
    cardShadow: AppShadows.cardDark,
    navigationShadow: AppShadows.navDark,
  );

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static AppSemanticColors forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

extension ThemeContextSemanticExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppSemanticColors get semanticColors => AppSemanticColors.of(this);
}
