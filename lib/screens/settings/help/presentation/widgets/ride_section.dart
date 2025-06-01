import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/help/presentation/pages/help_ride_screen.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';

import '../../../settings_screen/presentation/pages/chat_screen.dart';
import '../../../settings_screen/presentation/pages/privacy_screen.dart';

class RideSection extends StatelessWidget {
  const RideSection({super.key});

  void _openChatWithSupport(BuildContext context) {
    // إنشاء بيانات خدمة العملاء
    UserData adminUser = UserData(
      firstName: "خدمة",
      lastName: "العملاء",
      uid: "admin_support",
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
        "الرحالات",
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
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpRideScreen()));
                },
                title: "رحله",
                leading: SvgPicture.asset(AppIcons.car),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyScreen()));
                },
                title: "الامان و الخصوصيه",
                leading: SvgPicture.asset(AppIcons.privacy),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(AppIcons.chat),
                onTap: () => _openChatWithSupport(context),
              )
            ],
          ))
    ]);
  }
}
