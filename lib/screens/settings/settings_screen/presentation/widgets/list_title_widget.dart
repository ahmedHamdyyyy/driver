import 'package:flutter/material.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';

class CustomListTitleWidget extends StatelessWidget {
  final Widget? leading;
  final String title;
  final VoidCallback? onTap;

  const CustomListTitleWidget(
      {super.key, this.leading, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.sMedium16(color: AppColors.textColor),
      ),
      trailing: const Icon(
        Icons.arrow_forward_rounded,
        color: AppColors.gray,
      ),
    );
  }
}
