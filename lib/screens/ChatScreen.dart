import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../Services/ChatMessagesService.dart';
import '../components/ChatItemWidget.dart';
import '../model/ChatMessageModel.dart';
import '../model/FileModel.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'MainScreen.dart';

class ChatScreenOld extends StatefulWidget {
  final UserData? userData;
  final int? ride_id;
  final bool? show_history;

  ChatScreenOld({this.userData, this.ride_id, this.show_history});

  @override
  _ChatScreenOldState createState() => _ChatScreenOldState();
}

class _ChatScreenOldState extends State<ChatScreenOld> {
  String id = '';
  var messageCont = TextEditingController();
  var messageFocus = FocusNode();
  bool isMe = false;

  @override
  void initState() {
    super.initState();
    if (widget.show_history == true) {
      chatMessageService = ChatMessageService();
    } else {
      init();
    }
  }

  @override
  void dispose() {
    try {
      if (widget.userData?.uid != null && sender.uid != null) {
        chatMessageService.setUnReadStatusToTrue(
            senderId: sender.uid!, receiverId: widget.userData!.uid!);
      }
    } catch (e) {
      print('Error in dispose: $e');
    }
    super.dispose();
  }

  UserData sender = UserData(
    username: sharedPref.getString(USER_NAME) ?? 'مستخدم',
    uid: sharedPref.getString(UID) ?? '',
    playerId: sharedPref.getString(PLAYER_ID) ?? '',
  );

  init() async {
    try {
      final uid = sharedPref.getString(UID);
      if (uid == null || uid.isEmpty) {
        print('خطأ: لا يمكن تحديد هوية المستخدم');
        return;
      }

      id = uid;
      mIsEnterKey = sharedPref.getBool(IS_ENTER_KEY).validate();
      // mSelectedImage = sharedPref.getString(SELECTED_WALLPAPER).validate();
      chatMessageService = ChatMessageService();

      if (widget.userData?.uid != null && sender.uid != null) {
        chatMessageService.setUnReadStatusToTrue(
            senderId: sender.uid!, receiverId: widget.userData!.uid!);
      }
    } catch (e) {
      print('Error in init: $e');
    }
    setState(() {});
  }

  sendMessage({FilePickerResult? result}) async {
    if (result == null) {
      if (messageCont.text.trim().isEmpty) {
        messageFocus.requestFocus();
        return;
      }
    }

    // التأكد من وجود بيانات المستخدم والمرسل
    if (widget.userData?.uid == null || sender.uid == null) {
      print('خطأ: بيانات المحادثة غير مكتملة');
      return;
    }

    ChatMessageModel data = ChatMessageModel();
    data.receiverId = widget.userData!.uid!;
    data.senderId = sender.uid;
    data.message = messageCont.text;
    data.msg_topic = widget.ride_id?.toString() ?? "support";
    data.isMessageRead = false;
    data.createdAt = DateTime.now().millisecondsSinceEpoch;

    if (widget.userData!.uid == sharedPref.getString(UID)) {
      //
    }
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
    String userName = sharedPref.getString(USER_NAME) ?? 'مستخدم';

    // إرسال الإشعار مع فحص وجود playerId
    if (widget.userData!.playerId != null &&
        widget.userData!.playerId!.isNotEmpty) {
      notificationService
          .sendPushNotifications(
              f_name.isEmpty ? userName : "$f_name $l_name", messageCont.text,
              receiverPlayerId: widget.userData!.playerId)
          .catchError((error) => print('Notification error: $error'));
    }

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
      print('Send message error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          launchScreen(getContext, MainScreen(), isNewTask: true);
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    launchScreen(getContext, MainScreen(), isNewTask: true);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              SizedBox(width: 8),
              if (widget.show_history != true)
                ClipRRect(
                    borderRadius: BorderRadius.all(radiusCircular(20)),
                    child: commonCachedNetworkImage(
                        widget.userData!.profileImage.validate(),
                        fit: BoxFit.cover,
                        height: 40,
                        width: 40)),
              SizedBox(width: 8),
              if (widget.show_history != true)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                      widget.userData!.firstName
                              .validate()
                              .capitalizeFirstLetter() +
                          " ${widget.userData!.lastName.validate()}",
                      style: TextStyle(color: Colors.white)),
                ),
              if (widget.show_history == true)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("${language.lblRide} #${widget.ride_id} Messages",
                      style: boldTextStyle(color: Colors.white)),
                ),
            ],
          ),
          backgroundColor: primaryColor,
        ),
        body: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(
                  bottom: widget.show_history == true ? 20 : 76),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: PaginateFirestore(
                reverse: true,
                isLive: true,
                padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 0),
                physics: BouncingScrollPhysics(),
                query: widget.show_history == true
                    ? chatMessageService.rideSpecificChatMessagesWithPagination(
                        rideId: widget.ride_id?.toString() ?? "0")
                    : chatMessageService.chatMessagesWithPagination(
                        driverID: sharedPref.getString(UID) ?? '',
                        riderID: widget.userData?.uid ?? ''),
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
                  return ChatItemWidget(
                      data: data, historyModeOnly: widget.show_history == true);
                },
              ),
            ),
            if (widget.show_history != true)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Visibility(
                  visible: widget.show_history == true ? false : true,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius(),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 0.2,
                          blurRadius: 0.2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageCont,
                            decoration: InputDecoration(
                              focusColor: primaryColor,
                              border: InputBorder.none,
                              hintText: language.writeMessage,
                              hintStyle: secondaryTextStyle(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8),
                            ),
                            cursorColor: appStore.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            focusNode: messageFocus,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            style: primaryTextStyle(),
                            textInputAction: mIsEnterKey
                                ? TextInputAction.send
                                : TextInputAction.newline,
                            onSubmitted: (s) {
                              sendMessage();
                            },
                            maxLines: 5,
                          ),
                        ),
                        inkWellWidget(
                          child:
                              Icon(Icons.send, color: primaryColor, size: 25),
                          onTap: () {
                            sendMessage();
                          },
                        )
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
