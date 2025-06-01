import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/pages/language_screen.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/pages/who_are_we_screen.dart'
    show WhoAreWeScreen;
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/utils/Colors.dart';

import '../../../help/presentation/help_screen.dart';
import '../pages/chat_screen.dart';
import '../pages/privacy_screen.dart';

class MoreInfoSection extends StatelessWidget {
  const MoreInfoSection({super.key});

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
        "مزيد من المعلومات و الدعم",
        style: AppTextStyles.sSemiBold16(),
      ),
      const ResponsiveVerticalSpace(16),
      Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 0),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                title: "من نحن",
                leading: SvgPicture.asset(
                  AppIcons.info,
                  color: primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WhoAreWeScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تغيير اللغه",
                leading: SvgPicture.asset(
                  AppIcons.language,
                  color: primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LanguageScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(
                  AppIcons.chat,
                  color: primaryColor,
                ),
                onTap: () => _openChatWithSupport(context),
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "المساعده",
                leading: SvgPicture.asset(
                  AppIcons.help,
                  color: primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpMainScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "سياسه الخصوصيه",
                leading: SvgPicture.asset(
                  AppIcons.privacy,
                  color: primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyScreen()));
                },
              ),
            ],
          ))
    ]);
  }

  Widget customDivider() => const Divider(
        indent: 16,
        endIndent: 16,
        height: 1,
      );
}
