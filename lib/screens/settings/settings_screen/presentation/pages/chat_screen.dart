import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:taxi_driver/components/ChatItemWidget.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/ChatMessageModel.dart';
import 'package:taxi_driver/model/FileModel.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/Services/ChatMessagesService.dart';
import 'package:taxi_driver/Services/NotificationService.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

class ChatScreen extends StatefulWidget {
  final UserData? userData;
  final int? rideId;
  final bool isAdminChat;

  const ChatScreen(
      {super.key, this.userData, this.rideId, this.isAdminChat = true});

  // Static method to navigate to chat with app admin when "Contact Us" is clicked
  static void openAdminChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          isAdminChat: true,
        ),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String id = '';
  final messageCont = TextEditingController();
  final messageFocus = FocusNode();
  bool isLoading = true;
  UserData? adminData;
  bool mIsEnterKey = false;

  UserData sender = UserData(
    username: sharedPref.getString(USER_NAME),
    uid: sharedPref.getString(UID),
    playerId: sharedPref.getString(PLAYER_ID),
  );

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    try {
      if (widget.userData != null) {
        chatMessageService.setUnReadStatusToTrue(
            senderId: sender.uid!, receiverId: widget.userData!.uid!);
      }
    } catch (e) {
      log(e.toString());
    }
    super.dispose();
  }

  void init() async {
    try {
      id = sharedPref.getString(UID)!;
      bool? enterKey = sharedPref.getBool(IS_ENTER_KEY);
      mIsEnterKey = enterKey ?? false;

      chatMessageService = ChatMessageService();

      if (widget.isAdminChat) {
        // Create admin data - normally this would come from an API
        adminData = UserData(
          firstName: "مدير",
          lastName: "التطبيق",
          uid: "admin_uid", // Use a fixed admin UID
          playerId: "admin_player_id",
          profileImage:
              "https://ui-avatars.com/api/?name=Admin&background=4CAF50&color=fff",
          userType: ADMIN,
        );

        if (adminData != null) {
          chatMessageService.setUnReadStatusToTrue(
              senderId: sender.uid!, receiverId: adminData!.uid!);
        }
      } else if (widget.userData != null) {
        chatMessageService.setUnReadStatusToTrue(
            senderId: sender.uid!, receiverId: widget.userData!.uid!);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      log(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendMessage({FilePickerResult? result}) async {
    if (result == null) {
      if (messageCont.text.trim().isEmpty) {
        messageFocus.requestFocus();
        return;
      }
    }

    UserData? chatTarget = widget.isAdminChat ? adminData : widget.userData;

    if (chatTarget == null) {
      toast("خطأ: لا يمكن إرسال الرسالة. بيانات المحادثة غير متوفرة.");
      return;
    }

    ChatMessageModel data = ChatMessageModel();
    data.receiverId = chatTarget.uid!;
    data.senderId = sender.uid;
    data.message = messageCont.text;
    data.msg_topic =
        widget.rideId != null ? widget.rideId.toString() : "support";
    data.isMessageRead = false;
    data.createdAt = DateTime.now().millisecondsSinceEpoch;

    if (result != null) {
      if (result.files.single.path!.isNotEmpty) {
        data.messageType = MessageType.IMAGE.name;
      } else {
        data.messageType = MessageType.TEXT.name;
      }
    } else {
      data.messageType = MessageType.TEXT.name;
    }

    String f_name = sharedPref.getString(FIRST_NAME) ?? '';
    String l_name = sharedPref.getString(LAST_NAME) ?? '';

    notificationService
        .sendPushNotifications(
            f_name == ''
                ? sharedPref.getString(USER_NAME)!
                : f_name + " $l_name",
            messageCont.text,
            receiverPlayerId: chatTarget.playerId)
        .catchError(log);

    messageCont.clear();
    setState(() {});

    return await chatMessageService.addMessage(data).then((value) async {
      if (result != null) {
        FileModel fileModel = FileModel();
        fileModel.id = value.id;
        fileModel.file = File(result.files.single.path!);
        fileList.add(fileModel);

        setState(() {});
      }
    }).catchError((error) {
      toast(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
      bottomNavigationBar: buildBottomBar(),
    );
  }

  PreferredSizeWidget buildAppBar() {
    if (isLoading) {
      return AppBar(
        backgroundColor: primaryColor,
        title: Text('جاري التحميل...'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      );
    }

    UserData? chatTarget = widget.isAdminChat ? adminData : widget.userData;
    String title = widget.isAdminChat
        ? 'خدمة العملاء'
        : '${chatTarget?.firstName ?? ""} ${chatTarget?.lastName ?? ""}';

    return AppBar(
      backgroundColor: primaryColor,
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    UserData? chatTarget = widget.isAdminChat ? adminData : widget.userData;

    if (chatTarget == null) {
      return Center(
        child: Text(
          "خطأ في تحميل بيانات المحادثة",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: 80.h),
      child: PaginateFirestore(
        reverse: true,
        isLive: true,
        padding: EdgeInsets.all(16.r),
        physics: BouncingScrollPhysics(),
        query: widget.rideId != null
            ? chatMessageService.rideSpecificChatMessagesWithPagination(
                rideId: widget.rideId.toString())
            : widget.isAdminChat
                ? chatMessageService.chatMessagesWithPagination(
                    driverID: sharedPref.getString(UID),
                    riderID: chatTarget.uid!)
                : chatMessageService.chatMessagesWithPagination(
                    driverID: sharedPref.getString(UID),
                    riderID: chatTarget.uid!),
        itemsPerPage: PER_PAGE_CHAT_COUNT,
        shrinkWrap: true,
        onEmpty: Center(
          child: Text(
            "لا توجد رسائل بعد. ابدأ المحادثة الآن!",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (context, snap, index) {
          ChatMessageModel data = ChatMessageModel.fromJson(
              snap[index].data() as Map<String, dynamic>);
          data.isMe = data.senderId == sender.uid;
          return ChatItemWidget(data: data, historyModeOnly: false);
        },
      ),
    );
  }

  Widget buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.h,
        horizontal: 16.w,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 0),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: messageCont,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'اكتب رسالة',
                  hintStyle: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                cursorColor: primaryColor,
                focusNode: messageFocus,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: () => sendMessage(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: Colors.white, size: 24),
            ),
          )
        ],
      ),
    );
  }
}
