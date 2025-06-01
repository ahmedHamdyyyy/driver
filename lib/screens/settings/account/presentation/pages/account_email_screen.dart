import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';

import '../../../../../core/widget/appbar/back_app_bar.dart';
import '../../../../../core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class AccountEmailScreen extends StatefulWidget {
  const AccountEmailScreen({super.key});

  @override
  State<AccountEmailScreen> createState() => _AccountEmailScreenState();
}

class _AccountEmailScreenState extends State<AccountEmailScreen> {
  final TextEditingController controller = TextEditingController();
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
          // Set email to controller
          controller.text = value.data!.email ?? '';
        }
        setState(() => isLoading = false);
      });
    } catch (e) {
      toast(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> updateEmail() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => isLoading = true);

      try {
        await updateProfile(
          firstName: sharedPref.getString(FIRST_NAME),
          lastName: sharedPref.getString(LAST_NAME),
          userEmail: controller.text.trim(),
          contactNumber: sharedPref.getString(CONTACT_NUMBER),
          address: sharedPref.getString(ADDRESS),
        ).then((_) {
          // Update the shared preferences
          sharedPref.setString(USER_EMAIL, controller.text.trim());
          appStore.setUserEmail(controller.text.trim());

          toast("تم تحديث البريد الإلكتروني بنجاح");
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
    controller.dispose();
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
            const BackAppBar(title: "البريد الالكتروني"),
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
                          "تحديث البريد الالكتروني",
                          style: AppTextStyles.sSemiBold16(),
                        ),
                        const ResponsiveVerticalSpace(10),
                        Text(
                          "هذا البريد سيتم استخدامه لتلقي الاشعارات و تسجيل الدخول واسترداد حسابك",
                          style: AppTextStyles.sMedium16(),
                        ),
                        const ResponsiveVerticalSpace(24),
                        AppTextFormField(
                          controller: controller,
                          hint: 'ادخل البريد الالكتروني',
                          hintColor: AppColors.gray,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال البريد الإلكتروني';
                            }
                            // Basic email validation
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'الرجاء إدخال بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const ResponsiveVerticalSpace(24),
                        Observer(
                          builder: (_) => AppButtons.primaryButton(
                            title: "تحديث",
                            onPressed: updateEmail,
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
