import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_image.dart';

import '../../../utils/Colors.dart';

class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const BackAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 105.h,
        decoration: BoxDecoration(
          color: primaryColor,
          image: DecorationImage(
            image: AssetImage("assets/images/Vector (1).png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 20.h),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.spMin,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.arrow_forward, color: Colors.white)),
              ],
            ),
          ),
        ));
  }

  @override
  Size get preferredSize => Size.fromHeight(105.h);
}
