import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/app_input_fields/my_country_code_picker.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class AccountPhoneScreen extends StatefulWidget {
  const AccountPhoneScreen({super.key});

  @override
  State<AccountPhoneScreen> createState() => _AccountPhoneScreenState();
}

class _AccountPhoneScreenState extends State<AccountPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    setState(() => isLoading = true);
    try {
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
        if (value.data != null) {
          // Parse phone number and country code
          String contactNumber = value.data!.contactNumber ?? '';
          String countryCode =
              value.data!.country_code ?? '+966'; // Default Saudi Arabia code

          // Set the values to controllers
          phoneController.text = contactNumber;
          codeController.text = countryCode;
        }
        setState(() => isLoading = false);
      });
    } catch (e) {
      toast(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> updatePhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => isLoading = true);

      try {
        await updateProfile(
          firstName: sharedPref.getString(FIRST_NAME),
          lastName: sharedPref.getString(LAST_NAME),
          userEmail: sharedPref.getString(USER_EMAIL),
          contactNumber: phoneController.text.trim(),
          address: sharedPref.getString(ADDRESS),
          country_code: codeController.text.trim(),
        ).then((_) {
          // Update the shared preferences
          sharedPref.setString(CONTACT_NUMBER, phoneController.text.trim());

          toast("تم تحديث رقم الهاتف بنجاح");
          Navigator.pop(context);
        });
      } catch (e) {
        toast(e.toString());
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackAppBar(title: "رقم الهاتف"),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تحديث رقم الهاتف",
                          style: AppTextStyles.sSemiBold16(),
                        ),
                        const ResponsiveVerticalSpace(10),
                        Text(
                          "هذا الرقم لتلقي الالشعارات و تسجيل الدخول و استرداد حسابك",
                          style: AppTextStyles.sMedium16(),
                        ),
                        const ResponsiveVerticalSpace(24),
                        Row(
                          children: [
                            CustomCountryCodePicker(
                                codeController: codeController),
                            Expanded(
                              child: AppTextFormField(
                                controller: phoneController,
                                hint: 'ادخل رقم الهاتف',
                                hintColor: AppColors.gray,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال رقم الهاتف';
                                  }
                                  if (value.length < 9) {
                                    return 'رقم الهاتف قصير جدًا';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const ResponsiveVerticalSpace(24),
                        Observer(
                          builder: (_) => AppButtons.primaryButton(
                            title: "تحديث",
                            onPressed: updatePhoneNumber,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
