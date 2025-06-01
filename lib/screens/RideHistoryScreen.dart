import 'package:flutter/material.dart';
import 'package:taxi_driver/model/RideHistory.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart' as intl;

import '../main.dart';

class RideHistoryScreen extends StatefulWidget {
  final List<RideHistory> rideHistory;

  RideHistoryScreen({required this.rideHistory});

  @override
  RideHistoryScreenState createState() => RideHistoryScreenState();
}

class RideHistoryScreenState extends State<RideHistoryScreen> {
  ScrollController _scrollController = ScrollController();
  bool showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        if (!showFloatingButton) setState(() => showFloatingButton = true);
      } else {
        if (showFloatingButton) setState(() => showFloatingButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getFormattedDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      // Using Arabic locale for date formatting
      return intl.DateFormat('dd MMMM yyyy • hh:mm a', 'ar').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getArabicStatus(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'accepted':
        return 'تم قبول الطلب';
      case 'new_ride_requested':
        return 'طلب رحلة جديد';
      case 'arriving':
        return 'في الطريق';
      case 'arrived':
        return 'تم الوصول';
      case 'payment_pending':
        return 'في انتظار الدفع';
      default:
        return type.replaceAll("_", " ");
    }
  }

  String _translateMessage(String message) {
    // ترجمة الرسائل القادمة من الباك إند
    Map<String, String> translations = {
      'The ride is completed': 'تم اكتمال الرحلة',
      'New Ride requested': 'طلب رحلة جديد',
      'The driver accepted the request and is enroute to the start location':
          'قبل السائق الطلب وهو في الطريق إلى موقع الانطلاق',
      'The ride is cancelled': 'تم إلغاء الرحلة',
      'The driver has arrived at pickup location':
          'وصل السائق إلى موقع الانطلاق',
      'The ride is in progress': 'الرحلة قيد التنفيذ',
      'Payment is pending': 'الدفع معلق',
      'The driver is arriving': 'السائق في الطريق',
      'Ride started': 'بدأت الرحلة',
      'Driver is waiting': 'السائق في انتظارك',
      'Your ride has been assigned to': 'تم تعيين رحلتك إلى',
      'has accepted your ride request': 'قبل طلب رحلتك',
      'Your ride has been cancelled': 'تم إلغاء رحلتك',
      'Your ride has been completed': 'اكتملت رحلتك',
      'is arriving': 'في الطريق إليك',
      'has arrived at your pickup location': 'وصل إلى موقع الانطلاق',
      'Your ride is in progress': 'رحلتك قيد التنفيذ',
    };

    // البحث عن الترجمة المناسبة
    String translatedMessage = message;
    translations.forEach((eng, ar) {
      if (message.contains(eng)) {
        translatedMessage = translatedMessage.replaceAll(eng, ar);
      }
    });

    return translatedMessage;
  }

  Color _getStatusColor(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'arriving':
        return Colors.purple;
      case 'arrived':
        return Colors.teal;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          title: Text(
            'سجل الرحلات',
            style: boldTextStyle(color: Colors.white, size: 20),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                toast('قريباً - خاصية التصفية');
              },
            ),
          ],
        ),
        floatingActionButton: showFloatingButton
            ? FloatingActionButton(
                mini: true,
                backgroundColor: primaryColor,
                child: Icon(Icons.arrow_upward, color: Colors.white),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
              )
            : null,
        body: widget.rideHistory.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد سجل رحلات',
                      style: boldTextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 16, bottom: 85),
                itemCount: widget.rideHistory.length,
                itemBuilder: (context, index) {
                  RideHistory data = widget.rideHistory[index];
                  bool isFirst = index == 0;
                  bool isLast = index == widget.rideHistory.length - 1;
                  Color statusColor = _getStatusColor(data.historyType ?? '');

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: TimelineTile(
                      alignment: TimelineAlign.start,
                      isFirst: isFirst,
                      isLast: isLast,
                      indicatorStyle: IndicatorStyle(
                        color: statusColor,
                        width: 40,
                        height: 40,
                        indicator: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            border: Border.all(color: statusColor, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ImageIcon(
                            AssetImage(statusTypeIcon(type: data.historyType)),
                            color: statusColor,
                          ),
                        ),
                      ),
                      beforeLineStyle: LineStyle(
                        color: statusColor.withOpacity(0.3),
                        thickness: 2,
                      ),
                      afterLineStyle: LineStyle(
                        color: statusColor.withOpacity(0.3),
                        thickness: 2,
                      ),
                      endChild: Container(
                        margin: EdgeInsets.only(right: 16, bottom: 24),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getArabicStatus(data.historyType ?? ''),
                                  style: boldTextStyle(color: statusColor),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getFormattedDate(data.createdAt),
                                    style: secondaryTextStyle(
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                              ],
                            ),
                            if (data.historyMessage.validate().isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                _translateMessage(
                                    data.historyMessage.validate()),
                                style: primaryTextStyle(size: 14),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
