import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/shared/wallet_widget.dart';
import 'package:taxi_driver/model/WalletDetailModel.dart';
import 'package:taxi_driver/screens/settings/wallet_screens/presentation/widgets/add_payment_method_widget.dart';

class WalletAddPaymentMainContent extends StatelessWidget {
  final WalletDetailModel? walletDetails;
  final VoidCallback? onCardSaved;

  const WalletAddPaymentMainContent({
    super.key,
    this.walletDetails,
    this.onCardSaved,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        WalletWidget(
          walletCharged: walletDetails?.walletBalance != null,
          walletAmount: walletDetails?.totalAmount,
          currencyCode: walletDetails?.walletBalance?.currency,
        ),
        const ResponsiveVerticalSpace(24),
        AddPaymentMethodWidget(onCardSaved: onCardSaved)
      ]),
    );
  }
}
