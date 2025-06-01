import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver/utils/Colors.dart';
import '../utils/Extensions/extension.dart';

class AppTheme {
  //
  AppTheme._();

  static String? getFontFamily(BuildContext context) {
    // Use Cairo font for Arabic, Google Play for English
    final Locale locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') {
      return GoogleFonts.cairo().fontFamily;
    }
    return GoogleFonts.play().fontFamily;
  }

  static TextDirection getTextDirection(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  static ThemeData getThemeData(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return ThemeData(
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionHandleColor: primaryColor,
          selectionColor: primaryColor.withOpacity(0.3)),
      primarySwatch: createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: isArabic
          ? GoogleFonts.cairo().fontFamily
          : GoogleFonts.play().fontFamily,
      bottomNavigationBarTheme:
          BottomNavigationBarThemeData(backgroundColor: Colors.white),
      iconTheme: IconThemeData(color: scaffoldSecondaryDark),
      textTheme: TextTheme(titleLarge: TextStyle()),
      dialogBackgroundColor: Colors.white,
      unselectedWidgetColor: Colors.black,
      dividerColor: viewLineColor,
      cardColor: Colors.white,
      dialogTheme: DialogTheme(shape: dialogShape()),
      appBarTheme: AppBarTheme(
        color: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
      ),
    ).copyWith(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static final ThemeData lightTheme = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionHandleColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.3)),
    primarySwatch: createMaterialColor(primaryColor),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: GoogleFonts.play().fontFamily,
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: Colors.white),
    iconTheme: IconThemeData(color: scaffoldSecondaryDark),
    textTheme: TextTheme(titleLarge: TextStyle()),
    dialogBackgroundColor: Colors.white,
    unselectedWidgetColor: Colors.black,
    dividerColor: viewLineColor,
    cardColor: Colors.white,
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      color: primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData arabicTheme = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionHandleColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.3)),
    primarySwatch: createMaterialColor(primaryColor),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    // Use Cairo font for Arabic which is optimized for Arabic text rendering
    fontFamily: GoogleFonts.cairo(
      fontWeight: FontWeight.w500, // Medium weight for better readability
    ).fontFamily,
    // Apply Arabic-specific text theme
    textTheme: TextTheme(
      titleLarge: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.bold),
      titleMedium: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.normal),
      bodySmall: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.normal),
      labelLarge: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
          fontWeight: FontWeight.w600),
    ),
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: Colors.white),
    iconTheme: IconThemeData(color: scaffoldSecondaryDark),
    dialogBackgroundColor: Colors.white,
    unselectedWidgetColor: Colors.black,
    dividerColor: viewLineColor,
    cardColor: Colors.white,
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      color: primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: createMaterialColor(primaryColor),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldColorDark,
    fontFamily: GoogleFonts.nunito().fontFamily,
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: scaffoldSecondaryDark),
    iconTheme: IconThemeData(color: Colors.white),
    textTheme: TextTheme(titleLarge: TextStyle(color: textSecondaryColor)),
    dialogBackgroundColor: scaffoldSecondaryDark,
    unselectedWidgetColor: Colors.white60,
    dividerColor: Colors.white12,
    cardColor: scaffoldSecondaryDark,
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
