import 'package:flutter/material.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';

abstract class AppButtons {
  static Widget primaryButton(
      {String title = "",
      void Function()? onPressed,
      Color bgColor = AppColors.primary,
      EdgeInsetsGeometry? padding}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  static Widget secondaryButton(
      {String title = "",
      void Function()? onPressed,
      Color bgColor = AppColors.white,
      EdgeInsetsGeometry? padding}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shadowColor: const Color(0x26000000),
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xfff1f1f1), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
