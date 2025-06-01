import 'package:flutter/material.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    location.dispose();
    password.dispose();
    confirmPassword.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextFormField(
          controller: name,
          hint: 'اسم المستخدم',
        ),
        const ResponsiveVerticalSpace(16),
        AppTextFormField(
          controller: email,
          hint: 'البريد الالكتروني',
        ),
        const ResponsiveVerticalSpace(16),
        AppTextFormField(
          controller: phone,
          hint: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
        ),
        const ResponsiveVerticalSpace(16),
        AppTextFormField(
          controller: location,
          hint: 'الموقع',
          keyboardType: TextInputType.phone,
        ),
        const ResponsiveVerticalSpace(16),
        AppTextFormField(
          controller: password,
          hint: 'الرقم السري',
          keyboardType: TextInputType.phone,
        ),
        const ResponsiveVerticalSpace(16),
        AppTextFormField(
          controller: confirmPassword,
          hint: 'تأكيد الرقم السري',
          keyboardType: TextInputType.phone,
        ),
        const ResponsiveVerticalSpace(24),
        AppButtons.primaryButton(
            onPressed: () {
              NavigationService.pushNamed(RouterNames.otpScreen);
            },
            title: "إنشاء حساب"),
      ],
    );
  }
}
