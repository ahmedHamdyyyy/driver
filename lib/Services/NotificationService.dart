import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../utils/Constants.dart';

class NotificationService {
  Future<void> sendPushNotifications(String title, String content,
      {String? id, String? image, String? receiverPlayerId}) async {
    log('####$receiverPlayerId!');
    Map req = {
      'headings': {
        'en': title,
      },
      'contents': {
        'en': content,
      },
      'data': {
        'id': 'CHAT_${sharedPref.getInt(USER_ID)}',
      },
      'big_picture': image.validate().isNotEmpty ? image.validate() : '',
      'large_icon': image.validate().isNotEmpty ? image.validate() : '',
      //   'small_icon': mAppIconUrl,
      'app_id': mOneSignalAppIdRider,
      'include_player_ids': [receiverPlayerId],
      'android_group': mAppName,
      'android_channel_id': mOneSignalRiderChannelID,
      'ios_sound': 'default_app_sound.wav',
    };
    var header = {
      HttpHeaders.authorizationHeader: 'Basic $mOneSignalRestKeyRider',
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };

    Response res = await post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      body: jsonEncode(req),
      headers: header,
    );

    log(res.body);

    if (res.statusCode.isEven) {
    } else {
      throw 'Something Went Wrong';
    }
  }

  // إرسال إشعار بحالة المستند باللغة العربية
  Future<void> sendDocumentStatusNotification({
    required String documentName,
    required String status,
    String? reason,
    String? receiverPlayerId,
  }) async {
    if (receiverPlayerId == null || receiverPlayerId.isEmpty) {
      log('Receiver player ID is empty, cannot send notification');
      return;
    }

    String title = '';
    String content = '';

    // تحديد العنوان والمحتوى بناءً على حالة المستند
    if (status == 'approved' || status == 'معتمد') {
      title = 'تمت الموافقة على المستند';
      content =
          'تم اعتماد المستند $documentName بنجاح. يمكنك الآن قبول الرحلات.';
    } else if (status == 'rejected' || status == 'مرفوض') {
      title = 'تم رفض المستند';
      content = reason != null && reason.isNotEmpty
          ? 'تم رفض المستند $documentName: $reason'
          : 'تم رفض المستند $documentName. يرجى التحقق من متطلبات المستند وتحميله مرة أخرى.';
    } else {
      title = 'تحديث حالة المستند';
      content = 'المستند $documentName قيد المراجعة';
    }

    Map req = {
      'headings': {
        'en': title,
        'ar': title,
      },
      'contents': {
        'en': content,
        'ar': content,
      },
      'data': {
        'id': 'DOC_${sharedPref.getInt(USER_ID)}',
        'document_status': status,
        'document_name': documentName,
      },
      'app_id': mOneSignalAppIdRider,
      'include_player_ids': [receiverPlayerId],
      'android_group': mAppName,
      'android_channel_id': mOneSignalRiderChannelID,
      'ios_sound': 'default_app_sound.wav',
    };

    var header = {
      HttpHeaders.authorizationHeader: 'Basic $mOneSignalRestKeyRider',
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };

    try {
      Response res = await post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        body: jsonEncode(req),
        headers: header,
      );

      log('Document notification response: ${res.body}');

      if (!res.statusCode.isEven) {
        log('Error sending document notification: ${res.body}');
      }
    } catch (e) {
      log('Exception while sending document notification: $e');
    }
  }
}
