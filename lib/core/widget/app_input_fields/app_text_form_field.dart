import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constant/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final bool? enabled;
  final InputBorder? border;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function()? suffixTap;
  final TextInputType keyboardType;
  final TextInputAction action;
  final String hint;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final bool isPassword;
  final bool readOnly;
  final bool autoFocus;
  final String keyError;
  final Map<String, dynamic>? errors;
  final IconData? suffixIcon;
  final Widget? svgSuffixIcon;
  final int? maxLines;
  final TextStyle? inputTextStyle;
  final TextDirection? textDirection;
  final TextStyle? labelStyle;
  final int? maxLength;
  final Color? hintColor;

  const AppTextFormField(
      {super.key,
      required this.controller,
      this.keyboardType = TextInputType.text,
      required this.hint,
      this.prefixIcon,
      this.action = TextInputAction.next,
      this.isPassword = false,
      this.readOnly = false,
      this.autoFocus = false,
      this.validator,
      this.onChanged,
      this.prefixWidget,
      this.onTap,
      this.suffixTap,
      this.keyError = "",
      this.errors,
      this.suffixIcon,
      this.labelText,
      this.border,
      this.svgSuffixIcon,
      this.maxLines = 1,
      this.inputTextStyle,
      this.textDirection,
      this.enabled,
      this.labelStyle,
      this.maxLength,
      this.hintColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        cursorColor: AppColors.primary,
        enabled: enabled,
        maxLines: maxLines,
        controller: controller,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 16.spMin,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(
              color: hintColor ?? AppColors.primary,
              fontSize: 16.spMin,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
            suffixIcon: svgSuffixIcon,
            suffixIconConstraints:
                BoxConstraints(maxHeight: 20.h, maxWidth: 20.w)),
      ),
    );
  }
}
