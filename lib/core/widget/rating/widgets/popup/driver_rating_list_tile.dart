import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';

class DriverRatingListTile extends StatelessWidget {
  const DriverRatingListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
        visualDensity: const VisualDensity(
          horizontal: -4,
          vertical: 0,
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
        subtitle: const Text(
          'Revo - 2016',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 14,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: CircleAvatar(
          radius: 20.r,
          foregroundImage: const AssetImage(AppIcons.user),
        ),
        trailing: GestureDetector(
          onTap: () {
            NavigationService.pushNamed(RouterNames.complainsScreen);
          },
          child: const Text(
            'الشكاوي',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
        ));
  }
}
