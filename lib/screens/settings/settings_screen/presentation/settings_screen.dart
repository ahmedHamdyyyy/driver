import 'package:flutter/material.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/appbar/home_screen_app_bar.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/settings_screen_main_content.dart';
import 'package:taxi_driver/core/app_bar/search_field.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeScreenAppBar(),
          const ResponsiveVerticalSpace(10),
          /*  const TransformedSearchField(
            hintText: "ابحث عن ما تريد",
          ), */
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const SettingsScreenMainContent(),
            ),
          )
        ],
      ),
    );
  }
}
