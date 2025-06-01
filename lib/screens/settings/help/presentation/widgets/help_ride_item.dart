import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';

class HelpRideItem extends StatelessWidget {
  const HelpRideItem({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(RouterNames.rideProblemScreen);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              fit: BoxFit.fill,
              AppIcons.sedan,
              width: 38.spMin,
              height: 38.spMin,
            ),
            const ResponsiveHorizontalSpace(10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرحله من التسعين الي الجامعه',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'نوع الرحله : سياره فاخره',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'الرحله مكتمله',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w400,
                  ),
                )
              ],
            ),
            const Spacer(),
            const Column(
              children: [
                Text(
                  '200',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'ريال سعودي',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
