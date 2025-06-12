import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi_driver/screens/MainScreen.dart';
import 'package:taxi_driver/screens/SignInScreen.dart';
import 'package:taxi_driver/screens/onboarding/presentaion/onboarding_screen.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Images.dart';
import '../utils/LanguageVerification.dart';
import 'DocumentsScreen.dart';
import 'EditProfileScreen.dart';
import 'HomeScreen.dart';
import 'WalkThroughScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNotifyPermission();

    // Force Arabic language
    _forceArabicLanguage();
  }

  void _forceArabicLanguage() async {
    // Set Arabic as the default language
    await appStore.setLanguage('ar');

    // Save Arabic language preferences
    setValue(SELECTED_LANGUAGE_CODE, 'ar');
    setValue(SELECTED_LANGUAGE_COUNTRY_CODE, 'SA');
    setValue(IS_SELECTED_LANGUAGE_CHANGE, true);

    // Notify about language change
    LiveStream().emit(CHANGE_LANGUAGE);

    // Find Arabic language data
    if (defaultServerLanguageData != null &&
        defaultServerLanguageData!.isNotEmpty) {
      for (var langData in defaultServerLanguageData!) {
        if (langData.languageCode == 'ar') {
          selectedServerLanguageData = langData;
          break;
        }
      }
    }
  }

  void init() async {
    List<ConnectivityResult> b = await Connectivity().checkConnectivity();
    if (b.contains(ConnectivityResult.none)) {
      return toast(language.yourInternetIsNotWorking);
    }
    await driverDetail();

    await Future.delayed(Duration(seconds: 2));
    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      await Geolocator.requestPermission().then((value) async {
        launchScreen(context, OnboardingScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        Geolocator.getCurrentPosition().then((value) {
          sharedPref.setDouble(LATITUDE, value.latitude);
          sharedPref.setDouble(LONGITUDE, value.longitude);
        });
      }).catchError((e) {
        launchScreen(context, OnboardingScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      });
    } else {
      if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull &&
          appStore.isLoggedIn) {
        launchScreen(context, MainScreen(),
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      } else if (sharedPref.getString(UID).validate().isEmptyOrNull &&
          appStore.isLoggedIn) {
        updateProfileUid().then((value) async {
          await _checkDocumentStatusAndNavigate();
        });
      } else if (appStore.isLoggedIn) {
        await _checkDocumentStatusAndNavigate();
      } else {
        launchScreen(context, HomeScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      }
    }
  }

  Future<void> driverDetail() async {
    if (appStore.isLoggedIn) {
      await getUserDetail(userId: sharedPref.getInt(USER_ID))
          .then((value) async {
        await sharedPref.setInt(IS_ONLINE, value.data!.isOnline!);
        if (value.data!.status == REJECT || value.data!.status == BANNED) {
          toast(
              '${language.yourAccountIs} ${value.data!.status}. ${language.pleaseContactSystemAdministrator}');
          logout();
        }
        appStore.setUserEmail(value.data!.email.validate());
        appStore.setUserName(value.data!.username.validate());
        appStore.setFirstName(value.data!.firstName.validate());
        appStore.setUserProfile(value.data!.profileImage.validate());

        sharedPref.setString(USER_EMAIL, value.data!.email.validate());
        sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
        sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
      }).catchError((error) {});
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3DB44A), Color(0xFF1B6D24)],
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            'images/splash.svg',
            width: 180,
            height: 180,
          ),
        ),
      ),
    );
  }

  void _checkNotifyPermission() async {
    String versionNo =
        sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;

    await getLanguageList(versionNo).then((value) {
      appStore.setLoading(false);
      app_update_check = value.driver_version;
      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.length > 0) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());
          bool isSetLanguage =
              sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (int i = 0; i < value.data!.length; i++) {
              if (value.data![i].isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, value.data![i].languageCode);
                setValue(
                    SELECTED_LANGUAGE_COUNTRY_CODE, value.data![i].countryCode);
                appStore.setLanguage(value.data![i].languageCode!,
                    context: context);
                break;
              }
            }
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      } else {
        String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';
        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings =
              ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data!.length > 0) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
    if (await Permission.notification.isGranted) {
      init();
    } else {
      await Permission.notification.request();
      init();
    }
  }

  // Add new method to check document status and navigate accordingly
  // This ensures that:
  // - Approved documents → MainScreen
  // - Pending/Rejected documents → DocumentsScreen (fixed in place)
  Future<void> _checkDocumentStatusAndNavigate() async {
    try {
      final docs = await getDriverDocumentList();

      if (docs.data != null && docs.data!.isNotEmpty) {
        bool hasApprovedDocuments =
            docs.data!.any((doc) => doc.isVerified == 1);
        bool hasPendingDocuments = docs.data!.any((doc) => doc.isVerified == 0);
        bool hasRejectedDocuments =
            docs.data!.any((doc) => doc.isVerified == 2);

        if (hasApprovedDocuments &&
            !hasPendingDocuments &&
            !hasRejectedDocuments) {
          launchScreen(context, MainScreen(),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
              isNewTask: true);
        } else {
          launchScreen(context, DocumentsScreen(isShow: true),
              pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        }
      } else {
        if (sharedPref.getInt(IS_Verified_Driver) == 1) {
          launchScreen(context, MainScreen(),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          launchScreen(context, DocumentsScreen(isShow: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        }
      }
    } catch (error) {
      print('Error checking document status: $error');
      if (sharedPref.getInt(IS_Verified_Driver) == 1) {
        launchScreen(context, MainScreen(),
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      } else {
        launchScreen(context, DocumentsScreen(isShow: true),
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      }
    }
  }
}
