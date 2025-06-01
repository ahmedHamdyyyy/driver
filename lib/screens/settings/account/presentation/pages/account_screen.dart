import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/appbar/home_screen_app_bar.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';

import '../../../../../core/app_bar/search_field.dart';
import '../widgets/account_main_content.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeScreenAppBar(),
          /*   const TransformedSearchField(
            hintText: "ابحث عن ما تريد",
          ), */
          const ResponsiveVerticalSpace(5),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const AccountMainContent(),
            ),
          )
        ],
      ),
      //bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
