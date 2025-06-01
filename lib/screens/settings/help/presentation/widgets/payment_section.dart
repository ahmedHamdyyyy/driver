import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/constant/styles/app_text_style.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/help/domain/entity/help_page_entity.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';

import '../../../settings_screen/presentation/pages/chat_screen.dart';

class PaymentSection extends StatelessWidget {
  const PaymentSection({super.key});
  final String content = '''نحن نعتذر بصدق عن الإزعاج.
في بعض الأحيان يتعين على الكباتن التعامل مع عوامل خارجة عن سيطرتهم مثل حركة المرور أو أعمال الطرق أو التحويلات.

إذا شعرت أن الكابتن كان غير مسؤول وتسبب في زيادة رسوم رحلتك، فيرجى الإبلاغ عن المشكلة أدناه.

يرجى التواصل معنا خلال 7 أيام من وقوع الحادث، وإلا فلن نتمكن من مراجعة الأسعار''';

  void _openChatWithSupport(BuildContext context) {
    // إنشاء بيانات خدمة العملاء
    UserData adminUser = UserData(
      firstName: "خدمة",
      lastName: "العملاء",
      uid: "admin_support",
      username: "خدمة العملاء",
      profileImage:
          "https://ui-avatars.com/api/?name=Support&background=4CAF50&color=fff",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenOld(
          userData: adminUser,
          show_history: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "الدفع",
        style: AppTextStyles.sSemiBold16(),
      ),
      const ResponsiveVerticalSpace(16),
      Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 0),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                title: "مشكله في إنشاء محفظه",
                leading: SvgPicture.asset(AppIcons.wallet),
                onTap: () => _openChatWithSupport(context),
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "مشكله في شحن المحفظه",
                leading: SvgPicture.asset(AppIcons.wallet),
                onTap: () => _openChatWithSupport(context),
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "مشكله في إضافه بطاقه",
                onTap: () => _openChatWithSupport(context),
                leading: SvgPicture.asset(
                  AppIcons.visaCard,
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                ),
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(AppIcons.chat),
                onTap: () => _openChatWithSupport(context),
              ),
            ],
          ))
    ]);
  }

  Widget customDivider() => const Divider(
        indent: 16,
        endIndent: 16,
        height: 1,
      );
}
