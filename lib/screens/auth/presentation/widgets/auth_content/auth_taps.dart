import 'package:flutter/material.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/auth/presentation/widgets/auth_content/login_widget.dart';
import 'package:taxi_driver/screens/auth/presentation/widgets/auth_content/sign_up_widget.dart';

class AuthTaps extends StatefulWidget {
  const AuthTaps({super.key});

  @override
  State<AuthTaps> createState() => _AuthTapsState();
}

class _AuthTapsState extends State<AuthTaps> {
  bool login = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  login = false;
                });
              },
              child: Column(
                children: [
                  Text(
                    'إنشاء حساب',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: login ? AppColors.gray : AppColors.textColor),
                  ),
                  if (!login)
                    Container(
                      height: 2,
                      width: 50,
                      color: AppColors.primary,
                    )
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  login = true;
                });
              },
              child: Column(
                children: [
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: login ? AppColors.textColor : AppColors.gray),
                  ),
                  if (login)
                    Container(
                      height: 2,
                      width: 50,
                      color: AppColors.primary,
                    )
                ],
              ),
            ),
          ],
        ),
        const ResponsiveVerticalSpace(39),
        if (login) const LoginWidget(),
        if (!login) const SignUpWidget(),
      ],
    );
  }
}
