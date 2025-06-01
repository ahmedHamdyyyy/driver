import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';

class ChatTextField extends StatelessWidget {
  const ChatTextField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: SvgPicture.asset(AppIcons.emoji)),
          border: InputBorder.none,
          hintText: 'اكتب رساله',
          hintStyle: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 16,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
      ),
    );
  }
}
