import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/app_common.dart';
import '../core/widget/appbar/back_app_bar.dart';
import '../model/NotificationListModel.dart';
import '../utils/Constants.dart';
import 'ComplaintListScreen.dart';
import 'RideDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  int currentPage = 1;

  bool mIsLastPage = false;
  List<NotificationData> notificationData = [];

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (!mIsLastPage) {
          appStore.setLoading(true);

          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    getNotification(page: currentPage).then((value) {
      appStore.setLoading(false);
      mIsLastPage = value.notificationData!.length < currentPage;
      if (currentPage == 1) {
        notificationData.clear();
      }
      notificationData.addAll(value.notificationData!);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
  }

  Future<void> _onRefresh() async {
    currentPage = 1;
    mIsLastPage = false;

    try {
      final value = await getNotification(page: currentPage);
      notificationData.clear();
      notificationData.addAll(value.notificationData!);
      mIsLastPage = value.notificationData!.length < 10;
      setState(() {});
    } catch (error) {
      log(error);
      toast('حدث خطأ أثناء تحديث الإشعارات');
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _getArabicStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'new ride requested':
        return 'طلب رحلة جديد';
      case 'accepted':
        return 'تم القبول';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
      case 'canceled':
        return 'ملغية';
      case 'arriving':
        return 'في الطريق';
      case 'arrived':
        return 'وصل';
      case 'in_progress':
        return 'قيد التنفيذ';
      default:
        return status ?? '';
    }
  }

  String _getArabicMessage(String? message) {
    if (message == null) return '';

    return message
        .replaceAll('New Ride requested', 'تم طلب رحلة جديدة')
        .replaceAll(
            'The driver accepted the request and is enroute to the start location',
            'قبل السائق الطلب وهو في الطريق إلى نقطة الانطلاق')
        .replaceAll('The ride is completed', 'تم إكمال الرحلة بنجاح')
        .replaceAll('The ride has been cancelled', 'تم إلغاء الرحلة')
        .replaceAll('Driver is arriving', 'السائق في الطريق')
        .replaceAll('Driver has arrived', 'وصل السائق')
        .replaceAll('Ride is in progress', 'الرحلة قيد التنفيذ');
  }

  Color _getStatusColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_ride_requested':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'arriving':
        return Colors.purple;
      case 'arrived':
        return Colors.indigo;
      case 'in_progress':
        return Colors.teal;
      default:
        return primaryColor;
    }
  }

  IconData _getStatusIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_ride_requested':
        return Icons.notification_important;
      case 'accepted':
        return Icons.check_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      case 'arriving':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.play_arrow;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [
          BackAppBar(
            title: "سجل الإشعارات",
          ),
          Expanded(
            child: Observer(builder: (context) {
              return Stack(
                children: [
                  if (notificationData.isNotEmpty)
                    RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: primaryColor,
                      backgroundColor: Colors.white,
                      child: AnimationLimiter(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          itemCount: notificationData.length +
                              (appStore.isLoading ? 1 : 0),
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (_, index) {
                            if (index == notificationData.length) {
                              return Container(
                                padding: EdgeInsets.all(16.h),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            NotificationData data = notificationData[index];
                            return AnimationConfiguration.staggeredList(
                              delay: Duration(milliseconds: 100),
                              position: index,
                              duration: Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildNotificationCard(data),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    !appStore.isLoading
                        ? RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: primaryColor,
                            backgroundColor: Colors.white,
                            child: SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: _buildEmptyState(),
                              ),
                            ),
                          )
                        : SizedBox(),
                  if (appStore.isLoading && notificationData.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          SizedBox(height: 16.h),
                          Text(
                            'جاري تحميل الإشعارات...',
                            style: primaryTextStyle(
                                size: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData data) {
    Color statusColor = _getStatusColor(data.data?.type);
    IconData statusIcon = _getStatusIcon(data.data?.type);
    String arabicStatus = _getArabicStatus(data.data?.subject);
    String arabicMessage = _getArabicMessage(data.data?.message);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (data.data!.type == COMPLAIN_COMMENT) {
            launchScreen(context,
                ComplaintListScreen(complaint: data.data!.complaintId!));
          } else if (data.data!.subject! == 'Completed') {
            launchScreen(context, RideDetailScreen(orderId: data.data!.id!));
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                arabicStatus.isNotEmpty
                                    ? arabicStatus
                                    : (data.data?.subject ?? ''),
                                style:
                                    boldTextStyle(size: 16, color: statusColor),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                data.data?.id != null
                                    ? '#${data.data!.id}'
                                    : '',
                                style:
                                    boldTextStyle(size: 10, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDate(data.createdAt.validate()),
                          style: secondaryTextStyle(
                              size: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  arabicMessage.isNotEmpty
                      ? arabicMessage
                      : (data.data?.message ?? ''),
                  style: primaryTextStyle(size: 14, color: Colors.grey[800]),
                  textAlign: TextAlign.right,
                ),
              ),
              if (data.data?.type == 'new_ride_requested' ||
                  data.data?.subject == 'New Ride Requested')
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.red.withOpacity(0.1)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high,
                          color: Colors.orange, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        'يتطلب اتخاذ إجراء',
                        style: boldTextStyle(
                            size: 12, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64.r,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد إشعارات',
            style: boldTextStyle(size: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'ستظهر جميع إشعارات الرحلات والتحديثات هنا\nتأكد من تفعيل الإشعارات لتلقي التنبيهات',
            style: secondaryTextStyle(size: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 16.r),
                SizedBox(width: 8.w),
                Text(
                  'اسحب للأسفل للتحديث',
                  style: primaryTextStyle(size: 12, color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
