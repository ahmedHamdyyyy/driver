import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_driver/Services/AuthService.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/DocumentsScreen.dart';
import 'package:taxi_driver/screens/auth/presentation/widgets/auth_content/auth_appbar.dart';
import 'package:taxi_driver/utils/Extensions/context_extensions.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../languageConfiguration/LanguageDefaultJson.dart';
import '../model/ServiceModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'TermsConditionScreen.dart';
import 'SignInScreen.dart';

class SignUpScreen extends StatefulWidget {
  final bool isOtp;
  final bool socialLogin;

  final String? countryCode;
  final String? privacyPolicyUrl;
  final String? termsConditionUrl;
  final String? userName;

  SignUpScreen(
      {this.socialLogin = false,
      this.userName,
      this.isOtp = false,
      this.countryCode,
      this.privacyPolicyUrl,
      this.termsConditionUrl});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  AuthServices authService = AuthServices();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();

  // Keep these controllers but they won't be visible in UI
  TextEditingController carModelController = TextEditingController();
  TextEditingController carProductionController = TextEditingController();
  TextEditingController carPlateController = TextEditingController();
  TextEditingController carColorController = TextEditingController();

  FocusNode firstNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  bool isAcceptedTc = false;
  String countryCode = defaultCountryCode;

  List<ServiceList> listServices = [];
  int selectedService = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId().then((value) {
        //
      });
    }
    await getServices().then((value) {
      if (value.data != null && value.data!.isNotEmpty) {
        listServices.addAll(value.data!);
        setState(() {});
      }
    }).catchError((error) {
      log(error.toString());
    });
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);
        try {
          Map req = {
            'first_name': firstController.text.trim(),
            'last_name': "", // Empty value for last name
            'username': widget.socialLogin
                ? widget.userName
                : userNameController.text.trim(),
            'email': emailController.text.trim(),
            "user_type": "driver",
            "contact_number": widget.socialLogin
                ? '${widget.userName}'
                : '${phoneController.text.trim()}',
            "country_code":
                widget.socialLogin ? '${widget.countryCode}' : '$countryCode',
            'password': widget.socialLogin
                ? widget.userName
                : passController.text.trim(),
            "player_id": sharedPref.getString(PLAYER_ID).validate(),
            "user_detail": {
              'car_model': "", // Empty value for car model
              'car_color': "", // Empty value for car color
              'car_plate_number': "", // Empty value for car plate number
              'car_production_year': "", // Empty value for car production year
            },
            'service_id':
                listServices.isNotEmpty ? listServices[selectedService].id : 1,
          };

          // Register directly with the API, skip Firebase completely
          final signUpResponse = await signUpApi(req);

          if (signUpResponse != null) {
            // Store user information in SharedPreferences
            await sharedPref.setString(
                TOKEN, signUpResponse.data!.apiToken.validate());
            await sharedPref.setString(
                USER_TYPE, signUpResponse.data!.userType.validate());
            await sharedPref.setString(
                FIRST_NAME, signUpResponse.data!.firstName.validate());
            await sharedPref.setString(
                LAST_NAME, signUpResponse.data!.lastName.validate());
            await sharedPref.setString(
                CONTACT_NUMBER, signUpResponse.data!.contactNumber.validate());
            await sharedPref.setString(
                USER_EMAIL, signUpResponse.data!.email.validate());
            await sharedPref.setString(
                USER_NAME, signUpResponse.data!.username.validate());
            if (signUpResponse.data!.address != null) {
              await sharedPref.setString(
                  ADDRESS, signUpResponse.data!.address.validate());
            }
            await sharedPref.setInt(USER_ID, signUpResponse.data!.id ?? 0);
            if (signUpResponse.data!.gender != null) {
              await sharedPref.setString(
                  GENDER, signUpResponse.data!.gender.validate());
            }
            await sharedPref.setInt(
                IS_ONLINE, signUpResponse.data!.isOnline ?? 0);
            if (signUpResponse.data!.uid != null) {
              await sharedPref.setString(
                  UID, signUpResponse.data!.uid.validate());
            }
            await sharedPref.setString(
                LOGIN_TYPE, signUpResponse.data!.loginType.validate());
            await sharedPref.setInt(
                IS_Verified_Driver, signUpResponse.data!.isVerifiedDriver ?? 0);

            await appStore.setLoggedIn(true);
            await appStore.setUserEmail(signUpResponse.data!.email.validate());
            if (signUpResponse.data!.profileImage != null) {
              await appStore
                  .setUserProfile(signUpResponse.data!.profileImage.validate());
            }

            appStore.setLoading(false);
            toast('تم التسجيل بنجاح');

            // انتقل إلى شاشة تسجيل الدخول بعد التسجيل
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DocumentsScreen()),
                (route) => false);
          }
        } catch (error) {
          appStore.setLoading(false);
          toast('فشل التسجيل: ${error.toString()}');
        }
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthAppbar(),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: firstController,
                      focus: firstNameFocus,
                      nextFocus: emailFocus,
                      errorThisFieldRequired: language.thisFieldRequired,
                      decoration:
                          inputDecoration(context, label: language.firstName),
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      textFieldType: TextFieldType.EMAIL,
                      focus: emailFocus,
                      controller: emailController,
                      nextFocus: userNameFocus,
                      errorThisFieldRequired: language.thisFieldRequired,
                      decoration:
                          inputDecoration(context, label: language.email),
                    ),
                    SizedBox(height: 16),
                    if (widget.socialLogin != true)
                      AppTextField(
                        textFieldType: TextFieldType.USERNAME,
                        focus: userNameFocus,
                        controller: userNameController,
                        nextFocus: phoneFocus,
                        errorThisFieldRequired: language.thisFieldRequired,
                        decoration:
                            inputDecoration(context, label: language.userName),
                      ),
                    if (widget.socialLogin != true) SizedBox(height: 16),
                    if (widget.socialLogin != true)
                      AppTextField(
                        controller: phoneController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textFieldType: TextFieldType.PHONE,
                        focus: phoneFocus,
                        nextFocus: passFocus,
                        decoration: inputDecoration(
                          context,
                          label: language.phoneNumber,
                          prefixIcon: IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountryCodePicker(
                                  padding: EdgeInsets.zero,
                                  initialSelection: countryCode,
                                  showCountryOnly: false,
                                  dialogSize: Size(
                                      MediaQuery.of(context).size.width - 60,
                                      MediaQuery.of(context).size.height * 0.6),
                                  showFlag: true,
                                  showFlagDialog: true,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
                                  textStyle: primaryTextStyle(),
                                  dialogBackgroundColor:
                                      Theme.of(context).cardColor,
                                  barrierColor: Colors.black12,
                                  dialogTextStyle: primaryTextStyle(),
                                  searchDecoration: InputDecoration(
                                    focusColor: primaryColor,
                                    iconColor: Theme.of(context).dividerColor,
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .dividerColor)),
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryColor)),
                                  ),
                                  searchStyle: primaryTextStyle(),
                                  onInit: (c) {
                                    countryCode = c!.dialCode!;
                                  },
                                  onChanged: (c) {
                                    countryCode = c.dialCode!;
                                  },
                                ),
                                VerticalDivider(
                                    color: Colors.grey.withOpacity(0.5)),
                              ],
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.trim().isEmpty)
                            return language.thisFieldRequired;
                          return null;
                        },
                      ),
                    if (widget.socialLogin != true) SizedBox(height: 16),
                    if (widget.socialLogin != true)
                      AppTextField(
                        controller: passController,
                        focus: passFocus,
                        autoFocus: false,
                        textFieldType: TextFieldType.PASSWORD,
                        errorThisFieldRequired: language.thisFieldRequired,
                        decoration:
                            inputDecoration(context, label: language.password),
                      ),
                    SizedBox(height: 24),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: '${language.agreeToThe} ',
                              style: secondaryTextStyle()),
                          TextSpan(
                            text: language.termsConditions,
                            style: boldTextStyle(color: primaryColor, size: 14),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (widget.termsConditionUrl != null &&
                                    widget.termsConditionUrl!.isNotEmpty) {
                                  launchScreen(
                                      context,
                                      TermsConditionScreen(
                                          title: language.termsConditions,
                                          subtitle: widget.termsConditionUrl),
                                      pageRouteAnimation:
                                          PageRouteAnimation.Slide);
                                } else {
                                  toast(language.txtURLEmpty);
                                }
                              },
                          ),
                          TextSpan(text: ' & ', style: secondaryTextStyle()),
                          TextSpan(
                            text: language.privacyPolicy,
                            style: boldTextStyle(color: primaryColor, size: 14),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (widget.privacyPolicyUrl != null &&
                                    widget.privacyPolicyUrl!.isNotEmpty) {
                                  launchScreen(
                                      context,
                                      TermsConditionScreen(
                                          title: language.privacyPolicy,
                                          subtitle: widget.privacyPolicyUrl),
                                      pageRouteAnimation:
                                          PageRouteAnimation.Slide);
                                } else {
                                  toast(language.txtURLEmpty);
                                }
                              },
                          ),
                        ]),
                        textAlign: TextAlign.left,
                      ),
                      value: isAcceptedTc,
                      onChanged: (val) async {
                        isAcceptedTc = val!;
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => register(),
                        child: Text(
                          language.signUp,
                          style: boldTextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
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
      ),
    );
  }
}
