import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/rating/widgets/complain_screen/choose_complain_topics_dropdown.dart';
import 'package:taxi_driver/core/widget/rating/widgets/complain_screen/small_rating_widget.dart';

class ComplainScreenMainContent extends StatelessWidget {
  const ComplainScreenMainContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: const Color(0xFFF1FFF2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(
              horizontal: 0,
              vertical: -4,
            ),
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            title: const Text(
              'كريم السيد',
              style: TextStyle(
                color: Color(0xFF424242),
                fontSize: 14,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.30,
              ),
            ),
            subtitle: const SmallRatingWidget(isReadOnly: true),
            leading: CircleAvatar(
              radius: 20.r,
              foregroundImage: const AssetImage(AppIcons.user),
            ),
          ),
        ),
        const ResponsiveVerticalSpace(24),
        const ChooseComplainsTopicsDropDown(),
        const ResponsiveVerticalSpace(16),
        /*   const CommentsField(
          hintText: 'اكتب تفسير ......',
        ), */
        const ResponsiveVerticalSpace(24),
        AppButtons.primaryButton(
          onPressed: () {
            NavigationService.pushAndRemoveUntil(RouterNames.mainScreen);
          },
          title: 'إرسال',
        ),
      ],
    );
  }
}
