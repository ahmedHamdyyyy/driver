import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class AccountPasswordScreen extends StatefulWidget {
  const AccountPasswordScreen({super.key});

  @override
  State<AccountPasswordScreen> createState() => _AccountPasswordScreenState();
}

class _AccountPasswordScreenState extends State<AccountPasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isOldPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> changeUserPassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      if (newPasswordController.text != confirmPasswordController.text) {
        toast("كلمة المرور الجديدة وتأكيد كلمة المرور غير متطابقة");
        return;
      }

      setState(() => isLoading = true);

      try {
        Map req = {
          "old_password": oldPasswordController.text.trim(),
          "new_password": newPasswordController.text.trim(),
        };

        await changePassword(req).then((value) {
          toast(value.message ?? "تم تغيير كلمة المرور بنجاح");
          Navigator.pop(context);
        });
      } catch (e) {
        toast(e.toString());
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required Function(bool) onVisibilityChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        cursorColor: AppColors.primary,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 16.spMin,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.gray,
            fontSize: 16.spMin,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.30,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.gray,
            ),
            onPressed: () => onVisibilityChanged(!isVisible),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackAppBar(title: "الرقم السري"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تحديث الرقم السري",
                        style: AppTextStyles.sSemiBold16(),
                      ),
                      const ResponsiveVerticalSpace(10),
                      Text(
                        "يجب أن تكون كلمة المرور قوية وآمنة للحفاظ على حسابك",
                        style: AppTextStyles.sMedium16(),
                      ),
                      const ResponsiveVerticalSpace(24),
                      _buildPasswordField(
                        controller: oldPasswordController,
                        hint: 'ادخل الرقم السري القديم ',
                        isVisible: isOldPasswordVisible,
                        onVisibilityChanged: (value) {
                          setState(() {
                            isOldPasswordVisible = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور القديمة';
                          }
                          return null;
                        },
                      ),
                      const ResponsiveVerticalSpace(16),
                      _buildPasswordField(
                        controller: newPasswordController,
                        hint: 'ادخل الرقم السري الجديد ',
                        isVisible: isNewPasswordVisible,
                        onVisibilityChanged: (value) {
                          setState(() {
                            isNewPasswordVisible = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور الجديدة';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const ResponsiveVerticalSpace(16),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        hint: 'تأكيد الرقم السري الجديد ',
                        isVisible: isConfirmPasswordVisible,
                        onVisibilityChanged: (value) {
                          setState(() {
                            isConfirmPasswordVisible = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء تأكيد كلمة المرور الجديدة';
                          }
                          if (value != newPasswordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                      const ResponsiveVerticalSpace(24),
                      Observer(
                        builder: (_) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : changeUserPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 19, vertical: 14),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "تحديث",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
