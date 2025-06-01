import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver/screens/SplashScreen.dart';
import 'package:taxi_driver/store/AppStore.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/test_api.dart';

import 'AppTheme.dart';
import 'Services/ChatMessagesService.dart';
import 'Services/NotificationService.dart';
import 'Services/UserServices.dart';
import 'firebase_options.dart';
import 'languageConfiguration/AppLocalizations.dart';
import 'languageConfiguration/BaseLanguage.dart';
import 'languageConfiguration/LanguageDataConstant.dart';
import 'languageConfiguration/LanguageDefaultJson.dart';
import 'languageConfiguration/ServerLanguageResponse.dart';
import 'model/FileModel.dart';
import 'screens/NoInternetScreen.dart';
import 'utils/Extensions/app_common.dart';

LanguageJsonData? selectedServerLanguageData;
List<LanguageJsonData>? defaultServerLanguageData = [];

AppStore appStore = AppStore();
late SharedPreferences sharedPref;
Color textPrimaryColorGlobal = textPrimaryColor;
Color textSecondaryColorGlobal = textSecondaryColor;
Color defaultLoaderBgColorGlobal = Colors.white;

late BaseLanguage language;
final GlobalKey netScreenKey = GlobalKey();
final GlobalKey locationScreenKey = GlobalKey();

late List<FileModel> fileList = [];
bool mIsEnterKey = false;

ChatMessageService chatMessageService = ChatMessageService();
NotificationService notificationService = NotificationService();
UserService userService = UserService();

final navigatorKey = GlobalKey<NavigatorState>();

get getContext => navigatorKey.currentState?.overlay?.context;
late LocationPermission locationPermissionHandle;

var app_update_check = null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Crashlytics in non-debug mode
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (
    errorDetails,
  ) {
    FirebaseCrashlytics.instance
        .recordError(errorDetails.exception, errorDetails.stack, fatal: true);
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordFlutterError(
        FlutterErrorDetails(exception: error, stack: stack));
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };
  sharedPref = await SharedPreferences.getInstance();

  // Set default language to Arabic
  await appStore
      .setLanguage(sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? 'ar');

  await appStore.setIsGuest(sharedPref.getBool(IS_GUEST) ?? false,
      isInitializing: true);
  await appStore.setLoggedIn(sharedPref.getBool(IS_LOGGED_IN) ?? false,
      isInitializing: true);
  await appStore.setUserId(sharedPref.getInt(USER_ID) ?? 0,
      isInitializing: true);
  await appStore.setUserEmail(sharedPref.getString(USER_EMAIL).validate(),
      isInitialization: true);
  await appStore.setUserProfile(
      sharedPref.getString(USER_PROFILE_PHOTO).validate(),
      isInitialization: true);
  initJsonFile();
  await oneSignalSettings();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  @override
  void initState() {
    super.initState();
    init();

    // Force Arabic language if not already set
    if (appStore.selectedLanguage != 'ar') {
      Future.delayed(Duration.zero, () {
        appStore.setLanguage('ar', context: context);
        setValue(SELECTED_LANGUAGE_CODE, 'ar');
        setValue(SELECTED_LANGUAGE_COUNTRY_CODE, 'SA');
      });
    }
  }

  void init() async {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((e) {
      if (e.contains(ConnectivityResult.none)) {
        log('not connected');
        launchScreen(
            navigatorKey.currentState!.overlay!.context, NoInternetScreen());
      } else {
        if (netScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
        // toast('Internet is connected.');
        log('connected');
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
    connectivitySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      // Force RTL for Arabic
      final isRtl = true; // Always use RTL for Arabic app

      return ScreenUtilInit(
        designSize: const Size(375, 812), // Standard design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'تطبيق السائق',
            theme: AppTheme.arabicTheme, // Always use Arabic theme
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: MyBehavior(),
                child: Directionality(
                  textDirection: TextDirection.rtl, // Force RTL
                  child: child!,
                ),
              );
            },
            home: SplashScreen(),
            supportedLocales: [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            locale: Locale('ar', 'SA'), // Default to Arabic
            localizationsDelegates: [
              AppLocalizations(),
              CountryLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // Force Arabic locale
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == 'ar') {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
          );
        },
      );
    });
  }
}
