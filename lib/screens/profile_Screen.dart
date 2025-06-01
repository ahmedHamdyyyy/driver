import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../model/SettingModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'AboutScreen.dart';
import 'BankInfoScreen.dart';
import 'ChangePasswordScreen.dart';
import 'DeleteAccountScreen.dart';
import 'DocumentsScreen.dart';
import 'EarningScreen.dart';
import 'EditProfileScreen.dart';
import 'EmergencyContactScreen.dart';
import 'LanguageScreen.dart';
import 'RidesListScreen.dart';
import 'SignInScreen.dart';
import 'TermsConditionScreen.dart';
import 'VehicleScreen.dart';
import 'WalletScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  SettingModel settingModel = SettingModel();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تعديل الحساب",
            style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 16, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section with image and name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Observer(builder: (context) {
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: radius(),
                          child: commonCachedNetworkImage(
                              appStore.userProfile.validate(),
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "${sharedPref.getString(FIRST_NAME).validate().capitalizeFirstLetter()} ${sharedPref.getString(LAST_NAME).validate().capitalizeFirstLetter()}",
                                  style: boldTextStyle(size: 18)),
                              SizedBox(height: 4),
                              Text(appStore.userEmail,
                                  style: secondaryTextStyle()),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                Divider(thickness: 1, height: 32),

                // Account Settings Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(language.profile, style: boldTextStyle()),
                ),
                SizedBox(height: 8),
/* 
                settingItemWidget(
                  icon: Ionicons.person_outline,
                  title: "تعديل  الصوره",
                  onTap: () {
                    launchScreen(context, EditProfileScreen(isGoogle: false),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */
/* 
                settingItemWidget(
                  icon: Ionicons.car_sport_outline,
                  title: language.updateVehicleInfo,
                  onTap: () {
                    launchScreen(context, VehicleScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */

                /* settingItemWidget(
                  icon: Ionicons.call_outline,
                  title: language.emergencyContacts,
                  onTap: () {
                    launchScreen(context, EmergencyContactScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */

                /*    settingItemWidget(
                  icon: Ionicons.cash_outline,
                  title: language.earnings,
                  onTap: () {
                    launchScreen(context, EarningScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */

                settingItemWidget(
                  icon: Ionicons.document_text_outline,
                  title: language.documents,
                  onTap: () {
                    launchScreen(context, DocumentsScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ),

                /*     settingItemWidget(
                  icon: Ionicons.business_outline,
                  title: language.bankInfo,
                  onTap: () {
                    launchScreen(context, BankInfoScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */

                /* Divider(thickness: 1, height: 32),

                // App Settings Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(language.settings, style: boldTextStyle()),
                ),
                SizedBox(height: 8),

                Visibility(
                  visible: sharedPref.getString(LOGIN_TYPE) != LoginTypeOTP &&
                      sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle &&
                      sharedPref.getString(LOGIN_TYPE) != null,
                  child: settingItemWidget(
                      icon: Ionicons.ios_lock_closed_outline,
                      title: language.changePassword,
                      onTap: () {
                        launchScreen(context, ChangePasswordScreen(),
                            pageRouteAnimation: PageRouteAnimation.Slide);
                      }),
                ),

                settingItemWidget(
                    icon: Ionicons.language_outline,
                    title: language.language,
                    onTap: () {
                      launchScreen(context, LanguageScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),

                if (appStore.privacyPolicy != null)
                  settingItemWidget(
                      icon: Ionicons.document_outline,
                      title: language.privacyPolicy,
                      onTap: () {
                        if (appStore.privacyPolicy != null) {
                          launchScreen(
                              context,
                              TermsConditionScreen(
                                  title: language.privacyPolicy,
                                  subtitle: appStore.privacyPolicy),
                              pageRouteAnimation: PageRouteAnimation.Slide);
                        } else {
                          toast(language.txtURLEmpty);
                        }
                      }),

                if (appStore.mHelpAndSupport != null)
                  settingItemWidget(
                      icon: Ionicons.help_circle_outline,
                      title: language.helpSupport,
                      onTap: () {
                        if (appStore.mHelpAndSupport != null) {
                          launchUrl(Uri.parse(appStore.mHelpAndSupport!));
                        } else {
                          toast(language.txtURLEmpty);
                        }
                      }),

                if (appStore.termsCondition != null)
                  settingItemWidget(
                      icon: Ionicons.document_text_outline,
                      title: language.termsConditions,
                      onTap: () {
                        if (appStore.termsCondition != null) {
                          launchScreen(
                              context,
                              TermsConditionScreen(
                                  title: language.termsConditions,
                                  subtitle: appStore.termsCondition),
                              pageRouteAnimation: PageRouteAnimation.Slide);
                        } else {
                          toast(language.txtURLEmpty);
                        }
                      }),
 */
                /*      settingItemWidget(
                  icon: Ionicons.information_circle_outline,
                  title: language.aboutUs,
                  onTap: () {
                    launchScreen(context,
                        AboutScreen(settingModel: appStore.settingModel),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ), */

                /*  Divider(thickness: 1, height: 32),

                settingItemWidget(
                    icon: Ionicons.log_out_outline,
                    color: Colors.red,
                    title: language.logOut,
                    onTap: () {
                      showConfirmDialogCustom(context,
                          primaryColor: primaryColor,
                          dialogType: DialogType.CONFIRMATION,
                          title: language.areYouSureYouWantToLogoutThisApp,
                          positiveText: language.yes,
                          negativeText: language.no, onAccept: (v) async {
                        logout();
                      });
                    }),

                settingItemWidget(
                    icon: Ionicons.ios_trash_outline,
                    color: Colors.red,
                    title: language.deleteAccount,
                    onTap: () {
                      launchScreen(context, DeleteAccountScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }), */
              ],
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }

  Widget settingItemWidget(
      {required IconData icon,
      required String title,
      required Function() onTap,
      bool isLast = false,
      Widget? suffixIcon,
      Color? color}) {
    return inkWellWidget(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color != null
                      ? color.withOpacity(0.1)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: radius(defaultRadius)),
              child: Icon(icon,
                  size: 22, color: color != null ? color : primaryColor),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(title, style: primaryTextStyle(color: color))),
            suffixIcon != null
                ? suffixIcon
                : Icon(Icons.arrow_forward_ios,
                    color: dividerColor.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
