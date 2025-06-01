import 'package:flutter/material.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_image.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/screens/WalletScreen.dart';

import '../../../screens/settings/wallet_screens/presentation/pages/wallet_add_paymentMethod_screen.dart';

class WalletWidget extends StatelessWidget {
  final bool walletCharged;
  final bool addCharged;
  final num? walletAmount;
  final String? currencyCode;

  const WalletWidget({
    super.key,
    this.walletCharged = false,
    this.addCharged = false,
    this.walletAmount,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedAmount = walletAmount != null
        ? '${walletAmount.toString()} ${currencyCode ?? 'ريال سعودي'}'
        : '0 ريال سعودي';

    return Container(
      width: double.infinity,
      height: 156,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: AssetImage(AppImages.walletFrame),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (walletCharged || addCharged) ? 'رصيد المحفظه' : 'المحفظه',
            style: AppTextStyles.sMedium16(color: AppColors.white),
          ),
          Text(
            (walletCharged || addCharged) ? formattedAmount : 'لا يوجد محفظه',
            style: AppTextStyles.sMedium16(color: AppColors.white),
          ),
          const Spacer(),
          AppButtons.primaryButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WalletAddPaymentMethodScreen()));
              },
              title: walletCharged
                  ? 'شحن المحفظه'
                  : addCharged
                      ? 'برجاء ادخال القيمه'
                      : "إنشاء محفظه",
              bgColor: AppColors.white.withOpacity(.3)),
        ],
      ),
    );
  }
}
