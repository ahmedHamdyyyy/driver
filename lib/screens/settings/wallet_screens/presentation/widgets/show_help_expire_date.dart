import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_image.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';

void showHelpExpireDate(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        surfaceTintColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تاريخ انتهاء الصالحيه',
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(16),
                Text(
                  'من المفترض أن تتمكن من العثور على هذا التاريخ في الجانب الأمامي من البطاقة، أسفل رقم البطاقة.',
                  style: AppTextStyles.sMedium14(color: AppColors.gray),
                ),
                const ResponsiveVerticalSpace(28),
                Image.asset(
                  AppImages.cvvHelp,
                  height: 152.h,
                ),
                const ResponsiveVerticalSpace(31),
                AppButtons.primaryButton(
                    title: 'موافق',
                    onPressed: () {
                      Navigator.pop(context);
                    })
              ],
            )),
      );
    },
  );
}
