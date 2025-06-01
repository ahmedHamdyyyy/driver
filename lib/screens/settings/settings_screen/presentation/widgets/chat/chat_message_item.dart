import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/constant/app_colors.dart';

class ChatMessageItem extends StatelessWidget {
  const ChatMessageItem({
    super.key,
    required this.isMe,
  });
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 252.w,
        padding: const EdgeInsets.all(10),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          shadows: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
          color: isMe ? AppColors.primary : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(10),
              topRight: const Radius.circular(10),
              bottomLeft:
                  !isMe ? const Radius.circular(0) : const Radius.circular(10),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(10),
            ),
          ),
        ),
        child: Text(
          'هل يمكنك مساعدتي في حل هذه المشكلة؟ اسمحوا لي أن أعرف إذا كانت هناك حاجة إلى أي تفاصيل أخرى',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isMe ? AppColors.white : AppColors.black,
            fontSize: 16,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
      ),
    );
  }
}
