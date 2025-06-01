import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/help/presentation/widgets/payment_section.dart';
import 'package:taxi_driver/screens/settings/help/presentation/widgets/ride_section.dart';

class HelpScreenMainContent extends StatelessWidget {
  const HelpScreenMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(children: [
        RideSection(),
        ResponsiveVerticalSpace(24),
        PaymentSection()
      ]),
    );
  }
}
