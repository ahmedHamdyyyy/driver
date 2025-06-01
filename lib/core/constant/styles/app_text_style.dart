import 'package:flutter/material.dart';
import '../app_colors.dart';

extension AppTextStyles on TextStyle {
  static TextStyle sSemiBold16({Color color = AppColors.textColor}) =>
      TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle sSemiBold14({Color color = AppColors.gray}) =>
      TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700);

  static TextStyle sMedium16({Color color = AppColors.gray}) =>
      TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500);

  static TextStyle sMedium14({Color color = AppColors.primary}) =>
      TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle sRegular14({Color color = AppColors.textColor}) =>
      TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w400);
}
