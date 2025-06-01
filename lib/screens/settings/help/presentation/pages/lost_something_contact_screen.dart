import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/custom_navigation_bar.dart';

class LostSomethingContactScreen extends StatefulWidget {
  const LostSomethingContactScreen({super.key});

  @override
  State<LostSomethingContactScreen> createState() =>
      _LostSomethingContactScreenState();
}

class _LostSomethingContactScreenState
    extends State<LostSomethingContactScreen> {
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
                  "اضعت شي",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(16),
                Container(
                    height: 48.h,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(AppIcons.upload),
                        const ResponsiveHorizontalSpace(10),
                        Text(
                          "تحميل صوره",
                          style: AppTextStyles.sMedium16(),
                        )
                      ],
                    )),
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
