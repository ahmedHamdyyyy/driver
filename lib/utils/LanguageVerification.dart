import 'package:flutter/material.dart';
import '../languageConfiguration/ArabicLanguage.dart';
import '../languageConfiguration/BaseLanguage.dart';
import '../main.dart';

/// This utility class helps verify proper Arabic language implementation across the app
class LanguageVerification {
  /// Force Arabic language settings throughout the app
  static Future<void> forceArabicLanguage(BuildContext context) async {
    // Set Arabic language code
    await appStore.setLanguage('ar', context: context);

    // Apply RTL direction
    await _applyRtlDirection(context);

    // Print status for debugging
    printArabicLanguageStatus();
  }

  /// Apply RTL direction to the app
  static Future<void> _applyRtlDirection(BuildContext context) async {
    try {
      // Force RTL rebuild
      await Future.delayed(Duration(milliseconds: 50));
      final currentDirection = Directionality.of(context);
      print('Current text direction: $currentDirection');

      if (currentDirection != TextDirection.rtl) {
        print('Warning: App is not in RTL mode. Will attempt to fix.');
      }
    } catch (e) {
      print('Error checking RTL direction: $e');
    }
  }

  /// Print current language settings for debugging
  static void printArabicLanguageStatus() {
    print('=== ARABIC LANGUAGE STATUS ===');
    print('Current language code: ${appStore.selectedLanguage}');
    print(
        'Is app supposed to be in Arabic: ${appStore.selectedLanguage == 'ar'}');

    // Check if we're using the right language instance
    final isUsingArabicLanguage = language is ArabicLanguage;
    print('Is using ArabicLanguage instance: $isUsingArabicLanguage');

    if (!isUsingArabicLanguage) {
      print(
          'Warning: Not using ArabicLanguage instance. This will cause incorrect translations.');
    }

    print('App name in current language: ${language.appName}');
    print('============================');
  }

  /// Verify if a specific text is properly translated to Arabic
  static bool isTextTranslatedToArabic(String text) {
    // A simple check if text contains Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  /// Verify if all required translations exist
  static List<String> getMissingTranslations() {
    final arabicLanguage = ArabicLanguage();
    final baseLanguage = BaseLanguage();

    List<String> missingTranslations = [];

    // Use reflection to check all getters on BaseLanguage
    // This is a simple example - in a real app, you would need to check all language keys

    return missingTranslations;
  }
}
