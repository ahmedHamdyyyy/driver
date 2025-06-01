import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/Services/WalletService.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/model/WalletDetailModel.dart';
import 'package:taxi_driver/screens/settings/wallet_screens/presentation/widgets/wallet_add_payment_main_content.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

import '../../../../../core/widget/appbar/home_screen_app_bar.dart';

class WalletAddPaymentMethodScreen extends StatefulWidget {
  const WalletAddPaymentMethodScreen({super.key});

  @override
  State<WalletAddPaymentMethodScreen> createState() =>
      _WalletAddPaymentMethodScreenState();
}

class _WalletAddPaymentMethodScreenState
    extends State<WalletAddPaymentMethodScreen> {
  final WalletService _walletService = WalletService();
  WalletDetailModel? _walletDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletDetails();
  }

  Future<void> _loadWalletDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final walletDetails = await _walletService.getWalletDetails();
      if (mounted) {
        setState(() {
          _walletDetails = walletDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        toast('حدث خطأ أثناء تحميل بيانات المحفظة');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: 'المحفظه'),

          //  const HomeScreenAppBar(),..
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    child: WalletAddPaymentMainContent(
                      walletDetails: _walletDetails,
                      onCardSaved: _loadWalletDetails,
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
