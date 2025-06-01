import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/screens/onboarding/domain/entity.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingEntity onboardingEntity;

  final void Function()? onPressed;

  const OnboardingPage(
      {super.key, required this.onboardingEntity, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                100.h,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(height: 40.h),
                    Container(
                      height: 300.h,
                      width: double.infinity,
                      child: Image.asset(
                        onboardingEntity.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 31.w),
                      child: Column(
                        children: [
                          Text(
                            onboardingEntity.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24.0.spMin,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            onboardingEntity.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0.spMin,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    bottom: 100.h,
                    top: 30.h,
                  ),
                  child: Container(
                    width: double.infinity,
                    child: AppButtons.primaryButton(
                      title: onboardingEntity.buttonText,
                      onPressed: onPressed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
