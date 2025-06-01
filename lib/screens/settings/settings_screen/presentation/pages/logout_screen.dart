import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';

import '../../../../../main.dart';
import '../../../../../network/RestApis.dart';
import '../../../../../utils/Colors.dart';
import '../../../../../utils/Extensions/ConformationDialog.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "تسجيل خروج"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "تسجيل خروج",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(10),
                Text(
                  "هل انت متأكد من تسجيل الخروج ",
                  style: AppTextStyles.sMedium16(),
                ),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "خروج",
                  onPressed: () {
                    showConfirmDialogCustom(context,
                        primaryColor: primaryColor,
                        dialogType: DialogType.CONFIRMATION,
                        title: language.areYouSureYouWantToLogoutThisApp,
                        positiveText: language.yes,
                        negativeText: language.no, onAccept: (v) async {
                      logout();
                    });
                  },
                )
              ],
            ),
          )
        ],
      ),
      //bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
