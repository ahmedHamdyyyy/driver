import 'package:flutter/material.dart';

import 'BaseLanguage.dart';
import 'LanguageDataConstant.dart';
import 'ArabicLanguage.dart';

class AppLocalizations extends LocalizationsDelegate<BaseLanguage> {
  const AppLocalizations();

  @override
  Future<BaseLanguage> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ar':
        return ArabicLanguage();
      case 'en':
        return BaseLanguage();
      default:
        return BaseLanguage();
    }
  }

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  bool shouldReload(LocalizationsDelegate<BaseLanguage> old) => false;
}
