import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/shared/wallet_widget.dart';

class WalletScreenMainContent extends StatelessWidget {
  const WalletScreenMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const WalletWidget(
          walletCharged: true,
        ),
        const ResponsiveVerticalSpace(24),
        Text(
          'طرق الدفع',
          style: AppTextStyles.sSemiBold16(),
        ),
        const ResponsiveVerticalSpace(16),
        Row(
          children: [
            SvgPicture.asset(AppIcons.biCash),
            const ResponsiveHorizontalSpace(10),
            Text(
              'نقدي',
              style: AppTextStyles.sSemiBold14(),
            ),
          ],
        ),
        const ResponsiveVerticalSpace(24),
        InkWell(
          onTap: () {
            NavigationService.pushNamed(
                RouterNames.walletAddPaymentMethodScreen);
          },
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              '+ إضافه طريقه دفع',
              style: AppTextStyles.sSemiBold14(color: AppColors.primary),
            ),
            const Icon(Icons.arrow_forward_outlined, color: AppColors.primary)
          ]),
        ),
      ]),
    );
  }
}
