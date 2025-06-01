import 'package:flutter/material.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
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
          controller: phone,
          hint: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
        ),
        const ResponsiveVerticalSpace(24),
        AppButtons.primaryButton(
            onPressed: () {
              NavigationService.pushNamed(RouterNames.mainScreen);
            },
            title: "تسجيل دخول"),
      ],
    );
  }
}
