import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/pages/logout_screen.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';

import '../../../../../utils/Colors.dart';
import '../../../../VehicleScreen.dart';
import '../../../account/presentation/pages/account_screen.dart';
import '../../../wallet_screens/presentation/pages/add_paymentMethod_screen.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

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
                title: "إداره الحساب",
                leading: SvgPicture.asset(
                  AppIcons.accountIcon,
                  color: primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountScreen()));
                },
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
                          builder: (context) =>
                              const AddPaymentMethodScreen()));
                },
                title: "البطاقات البنكيه",
                leading: SvgPicture.asset(
                  AppIcons.payment,
                  color: primaryColor,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => VehicleScreen()));
                },
                title: "السياره",
                leading: SvgPicture.asset(
                  AppIcons.car,
                  color: primaryColor,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تسجيل خروج",
                leading: SvgPicture.asset(
                  AppIcons.logout,
                  color: primaryColor,
                ),
                onTap: () {
                  //   try {
//if (NavigationService.navigatorKey.currentState != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LogoutScreen()));
                },
              )
            ],
          ))
    ]);
  }
}
