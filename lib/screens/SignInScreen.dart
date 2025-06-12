import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/DocumentsScreen.dart';
import 'package:taxi_driver/screens/ForgotPasswordScreen.dart';
import 'package:taxi_driver/screens/MainScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/model/ServiceModel.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'TermsConditionScreen.dart';

import '../components/OTPDialog.dart';
import '../model/UserDetailModel.dart';
import '../utils/Extensions/AppButtonWidget.dart';

class SignInScreen extends StatefulWidget {
  final bool socialLogin;
  final String? countryCode;
  final String? userName;

  SignInScreen({this.socialLogin = false, this.countryCode, this.userName});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController signUpEmailController = TextEditingController();
  TextEditingController signUpPhoneController = TextEditingController();
  TextEditingController signUpPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  bool mIsCheck = false;
  bool isAcceptedTc = false;
  String? privacyPolicy;
  String? termsCondition;

  String countryCode = '+966'; // Default Saudi Arabia country code
  List<ServiceList> listServices = [];
  int selectedService = 0;

  BorderRadius radius(double r) => BorderRadius.circular(r);

  TextStyle primaryTextStyle({double size = 14, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontFamily: 'Tajawal',
      color: color ?? primaryColor,
      fontWeight: FontWeight.normal,
    );
  }

  TextStyle boldTextStyle({double size = 16, Color? color}) {
    return TextStyle(
      fontSize: size,
      color: color ?? Colors.black,
      fontWeight: FontWeight.bold,
    );
  }

  void launchScreen(BuildContext context, Widget screen,
      {bool isNewTask = false}) {
    if (isNewTask) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => screen),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    init();
  }

  void init() async {
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId();
    }
    mIsCheck = sharedPref.getBool(REMEMBER_ME) ?? false;
    if (mIsCheck) {
      emailController.text = sharedPref.getString(USER_EMAIL).validate();
      passController.text = sharedPref.getString(USER_PASSWORD).validate();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: primaryColor,
                  image: DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: radius(50),
                    child: Image.asset(
                      'assets/images/Artboard.png',
                      width: 100,
                      height: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, -40),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: primaryColor,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: [
                              Tab(text: language.logIn),
                              Tab(text: language.signUp),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: loginForm(),
                              ),
                              SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: signUpForm(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Observer(
            builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: emailController,
            focusNode: emailFocus,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              //labelText: language.email,
              hintText: "البريد الإلكتروني",
              hintStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              if (!s.trim().validateEmail()) return language.thisFieldRequired;
              return null;
            },
            onFieldSubmitted: (s) =>
                FocusScope.of(context).requestFocus(passFocus),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: passController,
            focusNode: passFocus,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            obscureText: true,
            decoration: InputDecoration(
              //labelText: language.password,
              hintText: "كلمة المرور",
              hintStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 18.0,
                    width: 18.0,
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: primaryColor,
                      value: mIsCheck,
                      shape: RoundedRectangleBorder(borderRadius: radius(4)),
                      onChanged: (v) async {
                        mIsCheck = v!;
                        if (!mIsCheck) {
                          sharedPref.remove(REMEMBER_ME);
                        } else {
                          await sharedPref.setBool(REMEMBER_ME, mIsCheck);
                          await sharedPref.setString(
                              USER_EMAIL, emailController.text);
                          await sharedPref.setString(
                              USER_PASSWORD, passController.text);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(language.rememberMe, style: primaryTextStyle(size: 14)),
                ],
              ),
              /*  TextButton(
                onPressed: () {
                  launchScreen(context, ForgotPasswordScreen());
                },
                child: Text(language.forgotPassword, style: primaryTextStyle()),
              ), */
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: primaryColor,
                  value: isAcceptedTc,
                  shape: RoundedRectangleBorder(borderRadius: radius(4)),
                  onChanged: (v) async {
                    isAcceptedTc = v!;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: language.iAgreeToThe + " ",
                        style: primaryTextStyle(size: 12),
                      ),
                      TextSpan(
                        text: language.termsConditions.splitBefore(' &'),
                        style: boldTextStyle(color: primaryColor, size: 14),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (termsCondition != null &&
                                termsCondition!.isNotEmpty) {
                              launchScreen(
                                context,
                                TermsConditionScreen(
                                  title: language.termsConditions,
                                  subtitle: termsCondition,
                                ),
                              );
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                      TextSpan(text: ' & ', style: primaryTextStyle(size: 12)),
                      TextSpan(
                        text: language.privacyPolicy,
                        style: boldTextStyle(color: primaryColor, size: 14),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (privacyPolicy != null &&
                                privacyPolicy!.isNotEmpty) {
                              launchScreen(
                                context,
                                TermsConditionScreen(
                                  title: language.privacyPolicy,
                                  subtitle: privacyPolicy,
                                ),
                              );
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                logIn();
              },
              child: Text(
                language.logIn,
                style: boldTextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget signUpForm() {
    return Form(
      key: signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: firstNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    //labelText: language.firstName,
                    hintText: "الاسم الأول",
                    hintStyle: TextStyle(color: primaryColor, fontSize: 14),
                    prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  validator: (s) {
                    if (s!.trim().isEmpty) return language.thisFieldRequired;
                    return null;
                  },
                ),
              ),
              /*    SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: lastNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: language.lastName,
                    prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  validator: (s) {
                    if (s!.trim().isEmpty) return language.thisFieldRequired;
                    return null;
                  },
                ),
              ),
            */
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: userNameController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              //labelText: language.userName,
              hintText: "اسم المستخدم",
              hintStyle: TextStyle(color: primaryColor, fontSize: 14),
              prefixIcon:
                  Icon(Icons.account_circle_outlined, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpEmailController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              //labelText: language.email,
              hintText: "البريد الإلكتروني",
              hintStyle: TextStyle(color: primaryColor, fontSize: 14),
              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              if (!s.trim().validateEmail()) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpPhoneController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              //labelText: language.phoneNumber,
              hintText: "رقم الهاتف",
              hintStyle: TextStyle(color: primaryColor, fontSize: 14),
              prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
              /*   prefixIcon: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryCodePicker(
                        /*  backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      initialSelection: countryCode,
                      showCountryOnly: false,
                      dialogSize: Size(MediaQuery.of(context).size.width - 60,
                          MediaQuery.of(context).size.height * 0.6),
                      showFlag: true,
                      showFlagDialog: true,
                      showOnlyCountryWhenClosed: false, */
                        /*    alignLeft: false,
                      textStyle: primaryTextStyle(),
                      //dialogBackgroundColor: Theme.of(context).cardColor,
                     // barrierColor: Colors.black12,
                      //dialogTextStyle: primaryTextStyle(),
                      searchDecoration: InputDecoration(
                        iconColor: Theme.of(context).dividerColor,
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor)),
                      ),
                      //searchStyle: primaryTextStyle(),
                      onInit: (c) {
                        countryCode = c!.dialCode!;
                      },
                      onChanged: (c) {
                        countryCode = c.dialCode!;
                      }, */
                        ),
                    //VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                  ],
                ),
              ), */
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpPasswordController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
            obscureText: true,
            decoration: InputDecoration(
              //labelText: language.password,
              hintText: "كلمة المرور",
              hintStyle: TextStyle(color: primaryColor, fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (String? value) {
              if (value!.isEmpty) return language.thisFieldRequired;
              if (value.length < 8)
                return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            obscureText: true,
            decoration: InputDecoration(
              //labelText: language.confirmPassword,
              hintText: "تأكيد كلمة المرور",
              hintStyle: TextStyle(color: primaryColor, fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (String? value) {
              if (value!.isEmpty) return language.thisFieldRequired;
              if (value.length < 8)
                return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
              if (value.trim() != signUpPasswordController.text.trim())
                return 'كلمتا المرور غير متطابقتين';
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: primaryColor,
                  value: isAcceptedTc,
                  shape: RoundedRectangleBorder(borderRadius: radius(4)),
                  onChanged: (v) async {
                    isAcceptedTc = v!;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: language.iAgreeToThe + " ",
                        style: primaryTextStyle(size: 12),
                      ),
                      TextSpan(
                        text: language.termsConditions.splitBefore(' &'),
                        style: boldTextStyle(color: primaryColor, size: 14),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (termsCondition != null &&
                                termsCondition!.isNotEmpty) {
                              launchScreen(
                                context,
                                TermsConditionScreen(
                                  title: language.termsConditions,
                                  subtitle: termsCondition,
                                ),
                              );
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                      TextSpan(text: ' & ', style: primaryTextStyle(size: 12)),
                      TextSpan(
                        text: language.privacyPolicy,
                        style: boldTextStyle(color: primaryColor, size: 14),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (privacyPolicy != null &&
                                privacyPolicy!.isNotEmpty) {
                              launchScreen(
                                context,
                                TermsConditionScreen(
                                  title: language.privacyPolicy,
                                  subtitle: privacyPolicy,
                                ),
                              );
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                register();
              },
              child: Text(
                language.signUp,
                style: boldTextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (signUpFormKey.currentState!.validate()) {
      signUpFormKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);

        Map req = {
          'first_name': firstNameController.text.trim(),
          'last_name': "",
          'username': userNameController.text.trim(),
          'email': signUpEmailController.text.trim(),
          "user_type": "driver",
          "contact_number": signUpPhoneController.text.trim(),
          "country_code": countryCode,
          'password': signUpPasswordController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          "user_detail": {
            'car_model': "",
            'car_color': "",
            'car_plate_number': "",
            'car_production_year': "",
          },
          'service_id':
              listServices.isNotEmpty ? listServices[selectedService].id : 1,
        };

        try {
          final response = await signUpApi(req);

          if (response.data != null) {
            // Store user information in SharedPreferences
            await sharedPref.setString(
                TOKEN, response.data!.apiToken.validate());
            await sharedPref.setString(
                USER_TYPE, response.data!.userType.validate());
            await sharedPref.setString(
                FIRST_NAME, response.data!.firstName.validate());
            await sharedPref.setString(
                LAST_NAME, response.data!.lastName.validate());
            await sharedPref.setString(
                USER_NAME, response.data!.username.validate());
            await sharedPref.setString(
                USER_EMAIL, response.data!.email.validate());
            await sharedPref.setString(
                CONTACT_NUMBER, response.data!.contactNumber.validate());
            await sharedPref.setInt(USER_ID, response.data!.id ?? 0);
            await sharedPref.setInt(IS_ONLINE, response.data!.isOnline ?? 0);

            if (response.data!.profileImage != null) {
              await sharedPref.setString(
                  'profile_image', response.data!.profileImage.validate());
            }

            // Set verification status to 0 (unverified)
            await sharedPref.setInt(IS_Verified_Driver, 0);

            // Set logged in state
            await appStore.setLoggedIn(true);

            appStore.setLoading(false);
            toast('تم التسجيل بنجاح');

            // Navigate to DocumentsScreen with isShow true to indicate new registration
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => DocumentsScreen(isShow: true)),
                (route) => false);
          }
        } catch (error) {
          appStore.setLoading(false);
          toast(error.toString());
        }
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  Future<void> logIn() async {
    hideKeyboard(context);
    if (loginFormKey.currentState!.validate()) {
      loginFormKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);
        Map req = {
          'email': emailController.text.trim(),
          'password': passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          'user_type': DRIVER,
        };
        if (mIsCheck) {
          await sharedPref.setBool(REMEMBER_ME, mIsCheck);
          await sharedPref.setString(USER_EMAIL, emailController.text);
          await sharedPref.setString(USER_PASSWORD, passController.text);
        }

        await logInApi(req).then((value) async {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            await checkPermission().then((value) async {
              await Geolocator.getCurrentPosition().then((value) {
                sharedPref.setDouble(LATITUDE, value.latitude);
                sharedPref.setDouble(LONGITUDE, value.longitude);
              });
            });
            launchScreen(context, MainScreen(), isNewTask: true);
          } else {
            launchScreen(context, DocumentsScreen(isShow: true),
                isNewTask: true);
          }
          appStore.setLoading(false);
        }).catchError((error) {
          appStore.setLoading(false);
          toast(error.toString());
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  void toast(String? message) {
    if (message == null) return;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
