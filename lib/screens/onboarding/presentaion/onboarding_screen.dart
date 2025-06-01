import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_image.dart';
import 'package:taxi_driver/screens/onboarding/domain/entity.dart';
import 'package:taxi_driver/screens/onboarding/presentaion/onboarding_page.dart';

import '../../../main.dart';
import '../../../utils/Constants.dart';
import '../../../utils/Extensions/app_common.dart';
import '../../SignInScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<OnboardingEntity> _pagesVendor = [
    OnboardingEntity(
      title: 'اعرض سعرك',
      subtitle:
          'قم بعرض سعرك المناسب للرحلة واحصل على المزيد من العملاء والأرباح المضمونة',
      image: AppImages.onboarding1,
      buttonText: 'ابدأ الآن',
    ),
    OnboardingEntity(
      title: 'قابل العميل في المكان المحدد',
      subtitle:
          'توجه إلى نقطة الالتقاء المحددة وقابل العميل في الوقت المناسب لبداية رحلة مريحة',
      image: AppImages.onboarding2,
      buttonText: 'التالي',
    ),
    OnboardingEntity(
      title: 'رحلة سعيدة',
      subtitle:
          'استمتع برحلة آمنة ومريحة مع عملائك واحصل على تقييمات إيجابية ودخل ثابت',
      image: AppImages.onboarding3,
      buttonText: 'ابدأ الآن',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pagesVendor.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (BuildContext context, int index) {
                return OnboardingPage(
                    onboardingEntity: _pagesVendor[index],
                    onPressed: () {
                      if (index == _pagesVendor.length - 1) {
                        sharedPref.setBool(IS_FIRST_TIME, false);
                        launchScreen(context, SignInScreen(), isNewTask: true);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
              },
            ),
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicator(),
              ),
            ),
            Positioned(
              top: 16.h,
              right: 16.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextButton(
                  onPressed: () {
                    sharedPref.setBool(IS_FIRST_TIME, false);
                    launchScreen(context, SignInScreen(), isNewTask: true);
                  },
                  child: Text(
                    "تخطي",
                    style: boldTextStyle(color: Colors.black, size: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _pagesVendor.length; i++) {
      indicators.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          child: i == _currentPage ? _indicator(true) : _indicator(false),
        ),
      );
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.lightGray,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
