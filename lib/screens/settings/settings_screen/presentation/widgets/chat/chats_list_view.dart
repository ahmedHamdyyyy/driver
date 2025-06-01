import 'package:flutter/material.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/widgets/chat/chat_date_section.dart';

class ChatsListView extends StatelessWidget {
  const ChatsListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ChatDateSection(),
            childCount: 1,
          ),
        ),
      ],
    );
  }
}
