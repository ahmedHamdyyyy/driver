import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/account/presentation/pages/account_email_screen.dart';
import 'package:taxi_driver/screens/settings/account/presentation/pages/account_name_screen.dart';
import 'package:taxi_driver/screens/settings/account/presentation/pages/account_password_screen.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';

import '../../../../../utils/Extensions/app_common.dart';
import '../../../../DocumentsScreen.dart';
import '../../../../EditProfileScreen.dart';
import '../../../settings_screen/presentation/widgets/list_title_widget.dart';
import '../pages/account_Phone_screen.dart';

class AccountMainContent extends StatelessWidget {
  const AccountMainContent({super.key});

  void _openChatWithSupport(BuildContext context) {
    // إنشاء بيانات المستخدم من SharedPreferences
    UserData adminUser = UserData(
      firstName: "خدمة",
      lastName: "العملاء",
      uid: "admin_support", // UID ثابت لخدمة العملاء
      username: "خدمة العملاء",
      profileImage:
          "https://ui-avatars.com/api/?name=Support&background=4CAF50&color=fff",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenOld(
          userData: adminUser,
          show_history: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "الحساب",
        style: AppTextStyles.sSemiBold16(),
      ),
      const ResponsiveVerticalSpace(16),
      Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                title: "الاسم",
                leading: SvgPicture.asset(AppIcons.teenyId),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AccountNameScreen()));
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AccountPhoneScreen()));
                },
                title: "رقم الهاتف",
                leading: SvgPicture.asset(AppIcons.phone),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AccountEmailScreen()));
                },
                title: "البريد الالكتروني",
                leading: Icon(
                  Icons.email_outlined,
                  color: Colors.grey,
                  size: 20.r,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  launchScreen(context, EditProfileScreen(isGoogle: false),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                title: "تغيير الصوره",
                leading: Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 20.r,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "الرقم السري",
                leading: SvgPicture.asset(AppIcons.lockPassword),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AccountPasswordScreen()));
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "المستندات",
                leading: SvgPicture.asset(AppIcons.car),
                onTap: () {
                  launchScreen(context, DocumentsScreen(),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تواصل معنا",
                leading: SvgPicture.asset(AppIcons.chat),
                onTap: () => _openChatWithSupport(context),
              )
            ],
          ))
    ]);
  }
}
