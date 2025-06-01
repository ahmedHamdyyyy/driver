import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
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
          const BackAppBar(title: "اللغه"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "تغيير اللغه",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(10),
                Text(
                  "برجاء اختيار اللغه التي تريدها",
                  style: AppTextStyles.sMedium16(),
                ),
                const ResponsiveVerticalSpace(24),
                AppTextFormField(
                    controller: controller,
                    hint: 'اللغه',
                    readOnly: true,
                    hintColor: AppColors.gray,
                    svgSuffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.gray,
                    )),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "تغيير",
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
