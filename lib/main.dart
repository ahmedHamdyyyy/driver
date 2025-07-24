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
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';

import 'AppTheme.dart';
import 'Services/ChatMessagesService.dart';
import 'Services/NotificationService.dart';
import 'Services/UserServices.dart';
import 'Services/DriverZegoService.dart';
import 'Services/ZegoDebugHelper.dart';
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

  // Print main initialization start
  if (kDebugMode) {
    print(
        '\n🚀 ══════════════════════════════════════════════════════════════');
    print('🚀 STARTING TAXI DRIVER APP WITH ZEGO INTEGRATION');
    print(
        '🚀 ══════════════════════════════════════════════════════════════\n');

    // Print startup debug info
    ZegoDebugHelper.printStartupInfo();
  }

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

  // Initialize OneSignal with phone number as External User ID
  await oneSignalSettings();

  // Verify and fix player_id if needed
  if (appStore.isLoggedIn) {
    await verifyAndFixPlayerId();
  }

  // Enhanced Zego Debug Logging
  if (kDebugMode) {
    print(
        '\n📞 ══════════════════════════════════════════════════════════════');
    print('📞 INITIALIZING ZEGO SYSTEM CALLING UI');
    print('📞 ══════════════════════════════════════════════════════════════');
    print('📞 App ID: $ZEGO_APP_ID');
    print('📞 App Sign: ${ZEGO_APP_SIGN.substring(0, 15)}...');
    print('📞 Navigator Key: ${navigatorKey.toString()}');
    print(
        '📞 ══════════════════════════════════════════════════════════════\n');
  }

  // Set navigator key to ZegoUIKitPrebuiltCallInvitationService
  try {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
    if (kDebugMode) {
      print('✅ Navigator key set successfully for Zego');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to set navigator key: $e');
    }
  }

  // Use system calling UI for offline call invitations with enhanced logging
  try {
    if (kDebugMode) {
      print(
          '\n🔧 ══════════════════════════════════════════════════════════════');
      print('🔧 SETTING UP ZEGO SYSTEM CALLING UI');
      print(
          '🔧 ══════════════════════════════════════════════════════════════');
    }

    ZegoUIKit().initLog().then((value) {
      if (kDebugMode) {
        print('📱 Zego UIKit log initialized');
        print('🔧 Setting up system calling UI with signaling plugin...');
      }

      ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
        [ZegoUIKitSignalingPlugin()],
      );

      if (kDebugMode) {
        print(
            '🎉 ══════════════════════════════════════════════════════════════');
        print('🎉 ZEGO SYSTEM CALLING UI SUCCESSFULLY INITIALIZED!');
        print('🎉 ✅ Ready to receive offline call invitations');
        print('🎉 ✅ Native calling interface active');
        print('🎉 ✅ Signaling plugin configured');
        print(
            '🎉 ══════════════════════════════════════════════════════════════\n');

        // Setup debug mode after successful initialization
        ZegoDebugHelper.setupDebugMode();
      }
    }).catchError((error) {
      if (kDebugMode) {
        print(
            '❌ ══════════════════════════════════════════════════════════════');
        print('❌ ZEGO SYSTEM CALLING UI INITIALIZATION FAILED!');
        print('❌ Error: $error');
        print(
            '❌ ══════════════════════════════════════════════════════════════\n');
      }
    });
  } catch (e) {
    if (kDebugMode) {
      print('❌ Exception during Zego setup: $e');
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kDebugMode) {
    print(
        '\n🏁 ══════════════════════════════════════════════════════════════');
    print('🏁 MAIN INITIALIZATION COMPLETE - LAUNCHING APP');
    print(
        '🏁 ══════════════════════════════════════════════════════════════\n');
  }

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
