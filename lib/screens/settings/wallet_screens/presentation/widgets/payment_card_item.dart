import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/app_image.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';

class PaymentCardItem extends StatelessWidget {
  final int selectedIndex;
  final bool canEdit;
  const PaymentCardItem(
      {super.key, this.selectedIndex = 0, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          selectedIndex == 0
              ? const CircleAvatar(
                  radius: 8,
                  backgroundColor: AppColors.primary,
                )
              : const CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.grey,
                ),
          const ResponsiveHorizontalSpace(10),
          Image.asset(
            AppImages.visa,
            width: 64.r,
            height: 58.h,
          ),
          const ResponsiveHorizontalSpace(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم البطاقه',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                RichText(
                    text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'رقم البطاقه : ',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16.spMin,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '*********765',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 14.spMin,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
          const ResponsiveHorizontalSpace(16),
          Column(
            children: [
              SvgPicture.asset(AppIcons.trash),
              if (canEdit)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: SvgPicture.asset(AppIcons.edit),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
