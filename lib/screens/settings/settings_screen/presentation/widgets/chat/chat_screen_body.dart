import 'package:flutter/material.dart';
import 'package:taxi_driver/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/chat/chats_list_view.dart';

class ChatScreenBody extends StatelessWidget {
  const ChatScreenBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackAppBar(
          title: 'خدمه العملاء',
        ),
        Expanded(
          child: ChatsListView(),
        )
      ],
    );
  }
}
