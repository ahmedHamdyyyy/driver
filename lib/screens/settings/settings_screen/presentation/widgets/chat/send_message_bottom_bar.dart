import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/core/utils/responsive_horizontal_space.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/chat/chat_text_field.dart';

class SendMessageBottomBar extends StatelessWidget {
  const SendMessageBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.h,
        horizontal: 16.w,
      ),
      decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
      child: Row(
        children: [
          const Expanded(
            child: ChatTextField(),
          ),
          const ResponsiveHorizontalSpace(16),
          GestureDetector(
            child: SvgPicture.asset(
              AppIcons.chatSend,
              width: 24.w,
              height: 24.h,
            ),
          )
        ],
      ),
    );
  }
}
