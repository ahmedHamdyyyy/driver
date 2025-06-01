import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/app_image.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Constants.dart';

import '../../../screens/NotificationScreen.dart';
import '../../../utils/Colors.dart' as AppColors show primaryColor;
import '../../../utils/Extensions/app_common.dart';
import '../../app_bar/user_icon.dart';

class HomeScreenAppBar extends StatefulWidget {
  const HomeScreenAppBar({
    super.key,
  });

  @override
  State<HomeScreenAppBar> createState() => _HomeScreenAppBarState();
}

class _HomeScreenAppBarState extends State<HomeScreenAppBar> {
  String userName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    try {
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
        if (value.data != null) {
          setState(() {
            final firstName = value.data!.firstName ?? '';
            final lastName = value.data!.lastName ?? '';
            userName = '$firstName $lastName'.trim();
            isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        final firstName = sharedPref.getString(FIRST_NAME) ?? '';
        final lastName = sharedPref.getString(LAST_NAME) ?? '';
        userName = '$firstName $lastName'.trim();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil if needed
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Container(
        width: double.infinity,
        height: 144.h,
        decoration: BoxDecoration(
          color: Color(0xFF3DB44A),
          image: DecorationImage(
            image: AssetImage("assets/images/Vector.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 21.w),
          child: Row(
            children: [
              const UserImage(),
              SizedBox(
                width: 9.w,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'اهلا بك في مسارك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  isLoading
                      ? const SizedBox(
                          height: 12,
                          width: 80,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white24,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        )
                      : Observer(
                          builder: (_) => Text(
                            userName.isEmpty ? appStore.userName : userName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  try {
                    launchScreen(context, NotificationScreen());
                  } catch (e) {
                    debugPrint('Navigation error: $e');
                  }
                },
                child: SvgPicture.asset(
                  AppIcons.notification,
                  width: 28.w,
                  height: 28.w,
                ),
              )
            ],
          ),
        ));
  }
}
