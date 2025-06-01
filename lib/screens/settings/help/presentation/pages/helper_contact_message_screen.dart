import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';
import 'package:taxi_driver/screens/settings/help/domain/entity/help_page_entity.dart';

class HelperContactMessageScreen extends StatelessWidget {
  final HelpPageEntity helpPageEntity;
  const HelperContactMessageScreen({super.key, required this.helpPageEntity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "المساعده"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helpPageEntity.title,
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(10),
                Text(
                  helpPageEntity.content,
                  style: AppTextStyles.sRegular14(),
                ),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "تواصل معانا",
                  onPressed: helpPageEntity.onTap,
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
