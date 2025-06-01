import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/rating/widgets/complain_screen/complain_screen_main_content.dart';

import '../../../appbar/back_app_bar.dart';

class ComplainScreenBody extends StatelessWidget {
  const ComplainScreenBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackAppBar(
              title: 'شكوة',
            ),
            const ResponsiveVerticalSpace(24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const ComplainScreenMainContent(),
            ),
          ],
        ));
  }
}
