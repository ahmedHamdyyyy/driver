import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/shared/wallet_widget.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/account_section.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/more_info_section.dart';

class SettingsScreenMainContent extends StatelessWidget {
  const SettingsScreenMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          WalletWidget(),
          ResponsiveVerticalSpace(24),
          AccountSection(),
          ResponsiveVerticalSpace(24),
          MoreInfoSection(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
