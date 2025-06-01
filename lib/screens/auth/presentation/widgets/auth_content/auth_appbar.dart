import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_driver/core/constant/app_image.dart';

class AuthAppbar extends StatelessWidget {
  const AuthAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 298,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.homeScreenAppBar),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            AppImages.splash,
            width: 114,
            height: 100,
          ),
        ));
  }
}
