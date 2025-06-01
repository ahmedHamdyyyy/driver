import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/chat/chat_message_list_view.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/chat/date_item.dart';

class ChatDateSection extends StatelessWidget {
  const ChatDateSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ResponsiveVerticalSpace(24),
        DateItem(),
        ResponsiveVerticalSpace(24),
        ChatMessagesListView(),
      ],
    );
  }
}
