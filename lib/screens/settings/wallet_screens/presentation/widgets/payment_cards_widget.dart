import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/wallet_screens/presentation/widgets/payment_card_item.dart';

class PaymentCardsWidget extends StatefulWidget {
  final bool canEdit;
  const PaymentCardsWidget({super.key, this.canEdit = false});

  @override
  State<PaymentCardsWidget> createState() => _PaymentCardsWidgetState();
}

class _PaymentCardsWidgetState extends State<PaymentCardsWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return PaymentCardItem(
              selectedIndex: index,
              canEdit: widget.canEdit,
            );
          },
          separatorBuilder: (context, index) {
            return const ResponsiveVerticalSpace(
              16,
            );
          },
          itemCount: 2,
        ),
        const ResponsiveVerticalSpace(16),
        InkWell(
          onTap: () {
            NavigationService.pushNamed(RouterNames.addPaymentCardScreen);
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 4,
                    offset: Offset(0, 0),
                    spreadRadius: 0,
                  ),
                ]),
            padding: EdgeInsets.symmetric(vertical: 19.h),
            child: Center(
                child: Text(
              '+ إضافه بطاقه',
              style: AppTextStyles.sSemiBold14(color: AppColors.primary),
            )),
          ),
        ),
      ],
    );
  }
}
