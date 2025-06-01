import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';

class AmountPaidContactScreen extends StatefulWidget {
  const AmountPaidContactScreen({super.key});

  @override
  State<AmountPaidContactScreen> createState() =>
      _AmountPaidContactScreenState();
}

class _AmountPaidContactScreenState extends State<AmountPaidContactScreen> {
  final TextEditingController controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "المساعده"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "المبلغ المدفوع للسائق",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(16),
                AppTextFormField(
                  controller: controller,
                  hint: 'برجاء ادخال القيمه',
                  hintColor: AppColors.gray,
                ),
                const ResponsiveVerticalSpace(16),
                Text("برجاء ادخال بعض التفاصيل",
                    style: AppTextStyles.sRegular14()),
                const ResponsiveVerticalSpace(16),
                AppTextFormField(
                  controller: controller,
                  hint: 'التفاصيل',
                  maxLines: 5,
                  hintColor: AppColors.gray,
                ),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "ارسال",
                  onPressed: () {},
                )
              ],
            ),
          )
        ],
      ),
      //bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
