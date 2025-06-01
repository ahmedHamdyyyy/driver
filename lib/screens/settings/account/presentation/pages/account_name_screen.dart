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

class AccountNameScreen extends StatefulWidget {
  const AccountNameScreen({super.key});

  @override
  State<AccountNameScreen> createState() => _AccountNameScreenState();
}

class _AccountNameScreenState extends State<AccountNameScreen> {
  final TextEditingController controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  String firstName = '';
  String lastName = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    setState(() => isLoading = true);
    try {
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
        if (value.data != null) {
          firstName = value.data!.firstName ?? '';
          lastName = value.data!.lastName ?? '';
          controller.text = "${firstName} ${lastName}".trim();
        }
        setState(() => isLoading = false);
      });
    } catch (e) {
      toast(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> saveUpdatedName() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => isLoading = true);

      // Split the full name into first and last name
      List<String> nameParts = controller.text.trim().split(' ');
      String updatedFirstName = nameParts.first;
      String updatedLastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      try {
        await updateProfile(
          firstName: updatedFirstName,
          lastName: updatedLastName,
          userEmail: sharedPref.getString(USER_EMAIL),
          contactNumber: sharedPref.getString(CONTACT_NUMBER),
          address: sharedPref.getString(ADDRESS),
        ).then((_) {
          toast("تم تحديث الاسم بنجاح");
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
    controller.dispose();
    super.dispose();
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
            const BackAppBar(title: "الاسم"),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تحديث الاسم",
                          style: AppTextStyles.sSemiBold16(),
                        ),
                        const ResponsiveVerticalSpace(10),
                        Text(
                          "اسمك يجعل من السهل على القبطان التأكد من الشخص الذي سياخذه",
                          style: AppTextStyles.sMedium16(),
                        ),
                        const ResponsiveVerticalSpace(24),
                        AppTextFormField(
                          controller: controller,
                          hint: 'ادخل الاسم كامل',
                          hintColor: AppColors.gray,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال الاسم';
                            }
                            return null;
                          },
                        ),
                        const ResponsiveVerticalSpace(24),
                        Observer(
                          builder: (_) => AppButtons.primaryButton(
                            title: "تحديث",
                            onPressed: saveUpdatedName,
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
