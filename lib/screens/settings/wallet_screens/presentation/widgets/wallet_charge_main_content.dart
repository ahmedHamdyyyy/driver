import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/shared/wallet_widget.dart';
import 'package:taxi_driver/screens/settings/wallet_screens/presentation/widgets/payment_cards_widget.dart';

class WalletAddChargeMainContent extends StatelessWidget {
  const WalletAddChargeMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        const WalletWidget(
          addCharged: true,
        ),
        const ResponsiveVerticalSpace(24),
        const PaymentCardsWidget(),
        const ResponsiveVerticalSpace(24),
        AppButtons.primaryButton(title: 'شحن', onPressed: () {}),
      ]),
    );
  }
}
