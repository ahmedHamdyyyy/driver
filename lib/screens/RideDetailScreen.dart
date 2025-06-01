import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/model/ComplaintModel.dart';
import 'package:taxi_driver/model/DriverRatting.dart';
import 'package:taxi_driver/model/RideHistory.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/screens/RideHistoryScreen.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/pages/chat_screen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/utils/Images.dart';

import '../core/widget/appbar/back_app_bar.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/RiderModel.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import 'ComplaintScreen.dart';
import 'PDF_Screen.dart';

class RideDetailScreen extends StatefulWidget {
  final int orderId;

  RideDetailScreen({required this.orderId});

  @override
  RideDetailScreenState createState() => RideDetailScreenState();
}

class RideDetailScreenState extends State<RideDetailScreen> {
  RiderModel? riderModel;
  List<RideHistory> rideHistory = [];
  DriverRatting? riderRatting;
  ComplaintModel? complaintData;
  Payment? payment;
  String? invoice_name;
  String? invoice_url;
  bool? isChatHistory;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void init() async {
    appStore.setLoading(true);
    try {
      isChatHistory = await chatMessageService.isRideChatHistory(
          rideId: widget.orderId.toString());

      await rideDetail(rideId: widget.orderId).then((value) {
        appStore.setLoading(false);

        riderModel = value.data;

        if (riderModel != null) {
          riderModel!.ride_has_bids = value.ride_has_bids;
        }

        invoice_name = value.invoice_name;
        invoice_url = value.invoice_url;

        if (value.rideHistory != null) {
          rideHistory.addAll(value.rideHistory!);
        }

        riderRatting = value.riderRatting;
        complaintData = value.complaintModel;

        if (value.payment != null) {
          payment = value.payment;
        }

        setState(() {});
      }).catchError((error, s) {
        setState(() {});
        appStore.setLoading(false);
        log('error:${error.toString()} STACK:::$s');
        toast('خطأ في تحميل تفاصيل الرحلة. يرجى المحاولة مرة أخرى.');
      });
    } catch (e, s) {
      appStore.setLoading(false);
      log('init error:${e.toString()} STACK:::$s');
      toast('خطأ في تحميل تفاصيل الرحلة. يرجى المحاولة مرة أخرى.');
      setState(() {});
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _getArabicStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
      case 'canceled':
        return 'ملغية';
      case 'accepted':
        return 'مقبولة';
      case 'pending':
        return 'في الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'arriving':
        return 'في الطريق';
      case 'arrived':
        return 'وصل';
      default:
        return status ?? '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'accepted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.teal;
      case 'arriving':
        return Colors.purple;
      case 'arrived':
        return Colors.indigo;
      default:
        return primaryColor;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Observer(
        builder: (context) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    BackAppBar(
                      title: riderModel != null
                          ? "تفاصيل الرحلة #${riderModel!.id}"
                          : "تفاصيل الرحلة",
                    ),
                    if (riderModel != null)
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerInfoCard(),
                            SizedBox(height: 16.h),
                            if (riderModel!.otherRiderData != null)
                              _buildAdditionalRiderCard(),
                            if (riderModel!.otherRiderData != null)
                              SizedBox(height: 16.h),
                            _buildRouteCard(),
                            SizedBox(height: 16.h),
                            _buildPriceCard(),
                            SizedBox(height: 16.h),
                            _buildPaymentCard(),
                            SizedBox(height: 16.h),
                            _buildActionsCard(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (appStore.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.r, vertical: 20.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'جاري تحميل البيانات...',
                            style: boldTextStyle(size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: primaryColor,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الرحلة',
                      style: boldTextStyle(size: 18, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'تفاصيل وبيانات الرحلة الأساسية',
                      style:
                          secondaryTextStyle(size: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            icon: Icons.confirmation_number,
            label: 'رقم الرحلة',
            value: '#${riderModel!.id}',
            color: primaryColor,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'تاريخ الطلب',
            value: _formatDate(riderModel!.createdAt),
            color: Colors.blue,
          ),
          if (riderModel!.distance != null) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.straighten,
              label: 'المسافة',
              value:
                  '${riderModel!.distance?.toStringAsFixed(2)} ${riderModel!.distanceUnit ?? 'كم'}',
              color: Colors.purple,
            ),
          ],
          if (invoice_url != null && invoice_url!.isNotEmpty) ...[
            /*   SizedBox(height: 16.h),
            InkWell(
              onTap: () {
                launchScreen(
                  context,
                  PDFViewer(
                    invoice: invoice_url!,
                    filename: invoice_name,
                  ),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                );
              },
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.green, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      'تحميل الفاتورة',
                      style: boldTextStyle(size: 14, color: Colors.green),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.green, size: 16.r),
                  ],
                ),
              ),
            ), */
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات العميل',
                      style: boldTextStyle(size: 18, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'بيانات العميل وتقييمه',
                      style:
                          secondaryTextStyle(size: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: commonCachedNetworkImage(
                    riderModel!.riderProfileImage.validate(),
                    height: 56.r,
                    width: 56.r,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riderModel!.riderName.validate(),
                      style: boldTextStyle(size: 16, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 8.h),
                    if (riderRatting != null)
                      Row(
                        children: [
                          RatingBar.builder(
                            direction: Axis.horizontal,
                            glow: false,
                            allowHalfRating: false,
                            ignoreGestures: true,
                            itemCount: 5,
                            itemSize: 16.r,
                            initialRating: double.parse(
                                (riderRatting!.rating ?? 0).toString()),
                            itemPadding: EdgeInsets.symmetric(horizontal: 1.w),
                            itemBuilder: (context, _) =>
                                Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (rating) {},
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '(${riderRatting!.rating ?? 0})',
                            style: secondaryTextStyle(
                                size: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (isChatHistory == true)
                InkWell(
                  onTap: () {
                    if (riderModel?.id != null) {
                      launchScreen(
                        context,
                        ChatScreen(rideId: riderModel!.id!),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.chat,
                      color: Colors.green,
                      size: 20.r,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalRiderCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_add,
                  color: Colors.orange,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'راكب إضافي',
                style: boldTextStyle(size: 18, color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'الاسم',
            value: riderModel!.otherRiderData?.name?.validate() ?? 'غير محدد',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.route,
                  color: Colors.green,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مسار الرحلة',
                      style: boldTextStyle(size: 18, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'نقاط البداية والوصول',
                      style:
                          secondaryTextStyle(size: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildRoutePoint(
            icon: Icons.radio_button_checked,
            color: Colors.green,
            title: 'نقطة الانطلاق',
            address: riderModel!.startAddress.validate(),
            time: riderModel!.startTime != null
                ? _formatDate(riderModel!.startTime!)
                : null,
          ),
          Container(
            margin: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
            child: DottedLine(
              direction: Axis.vertical,
              lineLength: 40.h,
              lineThickness: 2,
              dashLength: 4,
              dashColor: Colors.grey[400]!,
            ),
          ),
          _buildRoutePoint(
            icon: Icons.location_on,
            color: Colors.red,
            title: 'نقطة الوصول',
            address: riderModel!.endAddress.validate(),
            time: riderModel!.endTime != null
                ? _formatDate(riderModel!.endTime!)
                : null,
          ),
          if (riderModel!.multiDropLocation != null &&
              riderModel!.multiDropLocation!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            InkWell(
              onTap: () {
                showOnlyDropLocationsDialog(
                  context: context,
                  multiDropData: riderModel!.multiDropLocation!,
                );
              },
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_location, color: Colors.blue, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      'عرض المحطات الإضافية',
                      style: boldTextStyle(size: 14, color: Colors.blue),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.blue, size: 16.r),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16.h),
          InkWell(
            onTap: () {
              launchScreen(
                context,
                RideHistoryScreen(rideHistory: rideHistory),
                pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
              );
            },
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.purple, size: 20.r),
                  SizedBox(width: 8.w),
                  Text(
                    'عرض سجل الرحلة',
                    style: boldTextStyle(size: 14, color: Colors.purple),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.purple, size: 16.r),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.payments,
                  color: Colors.green,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'تفاصيل التكلفة',
                style: boldTextStyle(size: 18, color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (riderModel!.ride_has_bids == 1) ...[
            _buildPriceRow('المبلغ الإجمالي', riderModel!.totalAmount ?? 0,
                isTotal: true),
            if (riderModel!.couponData != null &&
                (riderModel!.couponDiscount ?? 0) != 0) ...[
              SizedBox(height: 8.h),
              _buildDiscountRow('خصم الكوبون', riderModel!.couponDiscount ?? 0),
            ],
            if (riderModel!.tips != null) ...[
              SizedBox(height: 8.h),
              _buildPriceRow('البقشيش', riderModel!.tips ?? 0),
            ],
          ] else ...[
            if ((riderModel!.subtotal ?? 0) <=
                (riderModel!.minimumFare ?? 0)) ...[
              _buildPriceRow(
                  'الحد الأدنى للأجرة', riderModel!.minimumFare ?? 0),
            ] else ...[
              _buildPriceRow('السعر الأساسي', riderModel!.baseFare ?? 0),
              SizedBox(height: 8.h),
              _buildPriceRow('سعر المسافة', riderModel!.perDistanceCharge ?? 0),
              SizedBox(height: 8.h),
              _buildPriceRow(
                  'سعر الدقيقة', riderModel!.perMinuteDriveCharge ?? 0),
              if ((riderModel!.perMinuteWaitingCharge ?? 0) != 0) ...[
                SizedBox(height: 8.h),
                _buildPriceRow(
                    'سعر الانتظار', riderModel!.perMinuteWaitingCharge ?? 0),
              ],
            ],
            if (riderModel!.surgeCharge != null &&
                riderModel!.surgeCharge! > 0) ...[
              SizedBox(height: 8.h),
              _buildPriceRow('رسوم إضافية', riderModel!.surgeCharge ?? 0),
            ],
            if (riderModel!.couponData != null &&
                (riderModel!.couponDiscount ?? 0) != 0) ...[
              SizedBox(height: 8.h),
              _buildDiscountRow('خصم الكوبون', riderModel!.couponDiscount ?? 0),
            ],
            if (payment != null && (payment!.driverTips ?? 0) != 0) ...[
              SizedBox(height: 8.h),
              _buildPriceRow('البقشيش', payment!.driverTips ?? 0),
            ],
          ],
          if (riderModel!.extraCharges != null &&
              riderModel!.extraCharges!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'رسوم إضافية',
              style: boldTextStyle(size: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8.h),
            ...riderModel!.extraCharges!
                .map((e) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _buildPriceRow(
                        e.key.validate().capitalizeFirstLetter(),
                        e.value ?? 0,
                      ),
                    ))
                .toList(),
          ],
          Container(
            margin: EdgeInsets.symmetric(vertical: 16.h),
            height: 1,
            color: Colors.grey[300],
          ),
          _buildTotalRow(),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: Colors.blue,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'تفاصيل الدفع',
                style: boldTextStyle(size: 18, color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            icon: Icons.payment,
            label: 'طريقة الدفع',
            value: _getArabicPaymentType(riderModel!.paymentType.validate()),
            color: Colors.blue,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            icon: Icons.check_circle,
            label: 'حالة الدفع',
            value:
                _getArabicPaymentStatus(riderModel!.paymentStatus.validate()),
            color: _getPaymentStatusColor(riderModel!.paymentStatus.validate()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      width: double.infinity,
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
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإجراءات المتاحة',
            style: boldTextStyle(size: 18, color: Colors.grey[800]),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.help_outline,
                  label: 'تقديم شكوى',
                  color: Colors.orange,
                  onTap: () {
                    if (riderModel == null) return;
                    launchScreen(
                      context,
                      ComplaintScreen(
                        driverRatting: riderRatting ?? DriverRatting(),
                        complaintModel: complaintData,
                        riderModel: riderModel,
                      ),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.star,
                  label: 'تقييم العميل',
                  color: Colors.amber,
                  onTap: () {
                    if (riderModel == null) return;
                    _showRatingDialog();
                  },
                ),
              ),
              if (isChatHistory == true) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat,
                    label: 'المحادثة',
                    color: Colors.green,
                    onTap: () {
                      if (riderModel?.id != null) {
                        launchScreen(
                          context,
                          ChatScreen(rideId: riderModel!.id!),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 16.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: secondaryTextStyle(size: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: primaryTextStyle(size: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    String? time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: boldTextStyle(size: 14, color: color),
              ),
              if (time != null) ...[
                SizedBox(height: 4.h),
                Text(
                  time,
                  style: secondaryTextStyle(size: 12, color: Colors.grey[600]),
                ),
              ],
              SizedBox(height: 4.h),
              Text(
                address,
                style: primaryTextStyle(size: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String title, num amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isTotal
              ? boldTextStyle(size: 16, color: Colors.grey[800])
              : secondaryTextStyle(size: 14, color: Colors.grey[600]),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ر.س',
          style: isTotal
              ? boldTextStyle(size: 16, color: Colors.green)
              : primaryTextStyle(size: 14, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildDiscountRow(String title, num amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: secondaryTextStyle(size: 14, color: Colors.grey[600]),
        ),
        Text(
          '- ${amount.toStringAsFixed(2)} ر.س',
          style: boldTextStyle(size: 14, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildTotalRow() {
    num totalAmount = riderModel!.totalAmount ?? 0;
    if (riderModel!.ride_has_bids == 1) {
      totalAmount += (riderModel!.tips ?? 0);
    } else {
      totalAmount += (payment?.driverTips ?? 0);
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المجموع الإجمالي',
            style: boldTextStyle(size: 16, color: Colors.green),
          ),
          Text(
            '${totalAmount.toStringAsFixed(2)} ر.س',
            style: boldTextStyle(size: 18, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.r),
            SizedBox(height: 8.h),
            Text(
              label,
              style: boldTextStyle(size: 12, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getArabicPaymentType(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'نقداً';
      case 'card':
      case 'credit_card':
        return 'بطاقة ائتمان';
      case 'wallet':
        return 'محفظة إلكترونية';
      default:
        return type;
    }
  }

  String _getArabicPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'مدفوع';
      case 'pending':
        return 'في الانتظار';
      case 'failed':
        return 'فشل';
      case 'refunded':
        return 'مسترد';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.r),
                        child: commonCachedNetworkImage(
                          riderModel!.riderProfileImage.validate(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riderModel!.riderName.validate(),
                          style: boldTextStyle(size: 16),
                        ),
                      ],
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (riderModel == null) return;
                        launchScreen(
                          context,
                          ComplaintScreen(
                            driverRatting: riderRatting ?? DriverRatting(),
                            complaintModel: complaintData,
                            riderModel: riderModel,
                          ),
                          pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                        );
                      },
                      child: Text(
                        'الشكاوي',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14.sp,
                          //decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 45.r,
                  unratedColor: Colors.grey[300],
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemBuilder: (context, _) => Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    _rating = rating;
                  },
                ),
                SizedBox(height: 24.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  width: double.infinity,
                  height: 45.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_rating == 0) {
                        toast('يرجى إضافة تقييم');
                        return;
                      }

                      appStore.setLoading(true);

                      try {
                        Map<String, dynamic> req = {
                          "ride_request_id": riderModel!.id,
                          "rating": _rating,
                          "comment": _reviewController.text.trim(),
                        };

                        await ratingReview(request: req).then((value) {
                          toast(value.message);
                          Navigator.pop(context);
                          init();
                        }).catchError((error) {
                          toast(error.toString());
                        });
                      } finally {
                        appStore.setLoading(false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34C759),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'إرسال',
                      style: boldTextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
