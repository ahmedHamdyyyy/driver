import 'package:flutter/material.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../main.dart';
import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../screens/MainScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';

class LanguageScreen extends StatefulWidget {
  @override
  LanguageScreenState createState() => LanguageScreenState();
}

class LanguageScreenState extends State<LanguageScreen> {
  bool isLoading = false;
  late List<LanguageData> languageOptions;
  String? selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    selectedLanguageCode =
        sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? defaultLanguageCode;

    // Automatically set to Arabic when screen loads
    Future.delayed(Duration.zero, () {
      if (selectedLanguageCode != 'ar') {
        setState(() {
          selectedLanguageCode = 'ar';
        });
      }
    });

    setupLanguageOptions();
  }

  void setupLanguageOptions() {
    // Define available languages
    languageOptions = [
      // English - use existing data if available
      LanguageData(
        id: 1,
        name: 'English',
        languageCode: 'en',
        countryCode: 'US',
        flag: 'https://flagcdn.com/w320/us.png',
        isRtl: 0,
      ),
      // Arabic
      LanguageData(
        id: 2,
        name: 'العربية', // Arabic name
        languageCode: 'ar',
        countryCode: 'SA',
        flag: 'https://flagcdn.com/w320/sa.png',
        isRtl: 1,
      ),
    ];
  }

  Future<void> selectLanguage(LanguageData data) async {
    setState(() {
      isLoading = true;
      selectedLanguageCode = data.languageCode;
    });

    try {
      // Find existing language data or create new one
      LanguageJsonData? languageData = findOrCreateLanguageData(data);

      if (languageData != null) {
        setValue(SELECTED_LANGUAGE_CODE, data.languageCode);
        setValue(SELECTED_LANGUAGE_COUNTRY_CODE, data.countryCode);
        selectedServerLanguageData = languageData;
        setValue(IS_SELECTED_LANGUAGE_CHANGE, true);

        await appStore.setLanguage(data.languageCode, context: context);
        LiveStream().emit(CHANGE_LANGUAGE);

        // Show language change success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(data.languageCode == 'ar'
                    ? 'تم تغيير اللغة إلى العربية'
                    : 'Language changed to English'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Restart app to apply language change completely
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false,
          );
        });
      }
    } catch (e) {
      print('Error changing language: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data.languageCode == 'ar'
            ? 'حدث خطأ أثناء تغيير اللغة'
            : 'Error changing language'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  LanguageJsonData? findOrCreateLanguageData(LanguageData data) {
    // First check if this language already exists in server data
    if (defaultServerLanguageData != null &&
        defaultServerLanguageData!.isNotEmpty) {
      for (var langData in defaultServerLanguageData!) {
        if (langData.languageCode == data.languageCode) {
          return langData;
        }
      }
    }

    // If not found, create a new one based on English
    if (defaultServerLanguageData != null &&
        defaultServerLanguageData!.isNotEmpty) {
      // Find English or any other language to use as base
      var baseLanguage = defaultServerLanguageData!.firstWhere(
        (lang) => lang.languageCode == 'en',
        orElse: () => defaultServerLanguageData!.first,
      );

      // Create new language data
      return LanguageJsonData(
        id: data.id,
        languageName: data.name,
        languageCode: data.languageCode,
        countryCode: data.countryCode,
        languageImage: data.flag,
        isRtl: data.isRtl,
        isDefaultLanguage: 0,
        contentData:
            baseLanguage.contentData, // Using English content data as a base
      );
    }

    return null;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.language,
            style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selection title
                Text(
                  'اختيار اللغة',
                  style: boldTextStyle(size: 20),
                ),

                SizedBox(height: 12),

                // Language description
                Text(
                  'يرجى اختيار لغتك المفضلة / Please select your preferred language',
                  style: secondaryTextStyle(),
                ),

                SizedBox(height: 32),

                // Language options
                Expanded(
                  child: ListView.builder(
                    itemCount: languageOptions.length,
                    itemBuilder: (context, index) {
                      final data = languageOptions[index];
                      final isSelected =
                          selectedLanguageCode == data.languageCode;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 0.5,
                                    offset: Offset(0, 5),
                                  )
                                ]
                              : null,
                        ),
                        child: Card(
                          elevation: isSelected ? 4 : 2,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                selectedLanguageCode = data.languageCode;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Flag image with better styling
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: commonCachedNetworkImage(
                                        data.flag,
                                        width: 60,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Language name with RTL support
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.name,
                                          style: boldTextStyle(
                                            size: 16,
                                            color: isSelected
                                                ? primaryColor
                                                : null,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (data.isRtl == 1)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .format_textdirection_r_to_l,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'يقرأ من اليمين إلى اليسار',
                                                style: secondaryTextStyle(
                                                    size: 12),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Selection indicator
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.withOpacity(0.2),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.grey.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(Icons.check,
                                            color: Colors.white, size: 18)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // زر حفظ اللغة
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: selectedLanguageCode != null
                        ? () {
                            // عند الضغط على الزر، تطبيق اللغة العربية
                            final selectedLanguage = languageOptions.firstWhere(
                              (element) =>
                                  element.languageCode == selectedLanguageCode,
                              orElse: () => languageOptions.first,
                            );
                            selectLanguage(selectedLanguage);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          selectedLanguageCode == 'ar'
                              ? "حفظ وتطبيق"
                              : "Save & Apply",
                          style: boldTextStyle(
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text(
                        selectedLanguageCode == 'ar'
                            ? 'جاري تغيير اللغة...'
                            : 'Changing language...',
                        style: primaryTextStyle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple data class to define available languages
class LanguageData {
  final int id;
  final String name;
  final String languageCode;
  final String countryCode;
  final String flag;
  final int isRtl;

  LanguageData({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.countryCode,
    required this.flag,
    required this.isRtl,
  });
}
