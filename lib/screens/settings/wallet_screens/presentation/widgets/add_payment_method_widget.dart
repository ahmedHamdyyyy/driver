import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/Services/WalletService.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/settings/wallet_screens/presentation/widgets/show_help_expire_date.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class AddPaymentMethodWidget extends StatefulWidget {
  final VoidCallback? onCardSaved;

  const AddPaymentMethodWidget({super.key, this.onCardSaved});

  @override
  State<AddPaymentMethodWidget> createState() => _AddPaymentMethodWidgetState();
}

class _AddPaymentMethodWidgetState extends State<AddPaymentMethodWidget> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  // Service
  final WalletService _walletService = WalletService();

  // Loading state
  bool _isLoading = false;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  // Validate card number with Luhn algorithm (basic validation)
  bool _isValidCardNumber(String cardNumber) {
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;

    // Remove any non-digit characters
    String sanitized = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (sanitized.isEmpty) return false;

    // Only basic length check for this implementation
    return sanitized.length >= 13 && sanitized.length <= 19;
  }

  // Validate expiry date in MM/YY format
  bool _isValidExpiryDate(String expiryDate) {
    if (expiryDate.length != 5) return false;

    try {
      List<String> parts = expiryDate.split('/');
      if (parts.length != 2) return false;

      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]) + 2000; // Assuming 20xx

      if (month < 1 || month > 12) return false;

      DateTime now = DateTime.now();
      DateTime cardDate = DateTime(year, month + 1, 0);

      return cardDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Validate CVV
  bool _isValidCVV(String cvv) {
    return cvv.length == 3 || cvv.length == 4;
  }

  // Format card number with spaces
  void _formatCardNumber(String value) {
    if (value.isEmpty) return;

    String digitsOnly = value.replaceAll(RegExp(r'\s+'), '');
    StringBuffer result = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        result.write(' ');
      }
      result.write(digitsOnly[i]);
    }

    // Only update if the formatted text is different
    if (_cardNumberController.text != result.toString()) {
      _cardNumberController.text = result.toString();
      // Place cursor at the end
      _cardNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cardNumberController.text.length),
      );
    }
  }

  // Format expiry date as MM/YY
  void _formatExpiryDate(String value) {
    if (value.isEmpty) return;

    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    String result = '';

    if (digitsOnly.length >= 1) {
      result = digitsOnly.substring(0, 1);
      if (digitsOnly.length >= 2) {
        result = digitsOnly.substring(0, 2);
        if (digitsOnly.length > 2) {
          result += '/' + digitsOnly.substring(2);
        }
      }
    }

    // Only update if the formatted text is different
    if (_expiryDateController.text != result) {
      _expiryDateController.text = result;
      // Place cursor at the end
      _expiryDateController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expiryDateController.text.length),
      );
    }
  }

  // Save card data
  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Format data
    final String cardHolder = _cardHolderController.text.trim();
    final String cardNumber =
        _cardNumberController.text.replaceAll(RegExp(r'\s'), '');
    final String cvv = _cvvController.text.trim();
    final String expiryDate = _expiryDateController.text.trim();

    try {
      bool success = await _walletService.saveCard(
        cardHolderName: cardHolder,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        userId: appStore.userId,
      );

      if (success) {
        toast('تم حفظ بيانات البطاقة بنجاح');
        if (widget.onCardSaved != null) {
          widget.onCardSaved!();
        }
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        toast('حدث خطأ أثناء حفظ البطاقة. يرجى المحاولة مرة أخرى');
      }
    } catch (e) {
      toast('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل البطاقه',
            style: AppTextStyles.sSemiBold16(),
          ),
          const ResponsiveVerticalSpace(16),
          AppTextFormField(
            hintColor: AppColors.gray,
            controller: _cardHolderController,
            hint: 'اسم حامل البطاقه',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال اسم حامل البطاقة';
              }
              return null;
            },
          ),
          const ResponsiveVerticalSpace(16),
          AppTextFormField(
            hintColor: AppColors.gray,
            controller: _cardNumberController,
            hint: 'رقم البطاقه',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _formatCardNumber(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال رقم البطاقة';
              }
              if (!_isValidCardNumber(value)) {
                return 'رقم البطاقة غير صالح';
              }
              return null;
            },
          ),
          const ResponsiveVerticalSpace(16),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  hintColor: AppColors.gray,
                  controller: _cvvController,
                  hint: 'CVV',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Limit to 4 digits for CVV
                    if (value.length > 4) {
                      _cvvController.text = value.substring(0, 4);
                      _cvvController.selection = TextSelection.fromPosition(
                        TextPosition(offset: 4),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال CVV';
                    }
                    if (!_isValidCVV(value)) {
                      return 'CVV غير صالح';
                    }
                    return null;
                  },
                  svgSuffixIcon: InkWell(
                    onTap: () {
                      showHelpExpireDate(context);
                    },
                    child: SvgPicture.asset(
                      AppIcons.help,
                      width: 18.w,
                      height: 18.h,
                    ),
                  ),
                ),
              ),
              const ResponsiveHorizontalSpace(15),
              Expanded(
                child: AppTextFormField(
                  hintColor: AppColors.gray,
                  controller: _expiryDateController,
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _formatExpiryDate(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال تاريخ الانتهاء';
                    }
                    if (!_isValidExpiryDate(value)) {
                      return 'تاريخ غير صالح';
                    }
                    return null;
                  },
                  svgSuffixIcon: InkWell(
                    onTap: () {
                      showHelpExpireDate(context);
                    },
                    child: SvgPicture.asset(
                      AppIcons.help,
                      width: 18.w,
                      height: 18.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const ResponsiveVerticalSpace(24),
          AppButtons.primaryButton(
            title: _isLoading ? 'جاري الحفظ...' : 'حفظ',
            onPressed: _isLoading ? null : _saveCard,
          )
        ],
      ),
    );
  }
}
