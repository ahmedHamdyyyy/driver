import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/components/CreateTabScreen.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:taxi_driver/model/RiderModel.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/screens/RideDetailScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../core/widget/appbar/home_screen_app_bar.dart';

class RidesListScreen extends StatefulWidget {
  @override
  RidesListScreenState createState() => RidesListScreenState();
}

class RidesListScreenState extends State<RidesListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int currentPage = 1;
  int totalPage = 1;
  List<String> riderStatus = [PENDING, 'active', COMPLETED, CANCELED, 'all'];
  Map<String, List<RiderModel>> tabData = {
    PENDING: [],
    'active': [],
    COMPLETED: [],
    CANCELED: [],
    'all': [],
  };
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  Timer? _refreshTimer;
  int _lastPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController!.addListener(_handleTabChange);
    init();
    _startAutoRefresh();
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      setState(() {
        isLoading = true;
      });
    } else {
      String currentStatus = riderStatus[_tabController!.index];
      if (tabData[currentStatus]?.isEmpty ?? true) {
        refreshData();
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_tabController?.index == 0 && mounted) {
        _checkForNewRequests();
      }
    });
  }

  void _checkForNewRequests() async {
    try {
      await getRiderRequestList(
        page: 1,
        status: PENDING,
        driverId: sharedPref.getInt(USER_ID),
      ).then((value) {
        List<RiderModel> pendingRides = value.data!
            .where((ride) =>
                ride.status == PENDING || ride.status == NEW_RIDE_REQUESTED)
            .toList();

        int newPendingCount = pendingRides.length;

        if (newPendingCount > _lastPendingCount && _lastPendingCount > 0) {
          _showNewRequestNotification(newPendingCount - _lastPendingCount);
        }

        _lastPendingCount = newPendingCount;

        if (_tabController?.index == 0) {
          setState(() {
            tabData[PENDING]?.clear();
            tabData[PENDING]?.addAll(pendingRides);
          });
        }
      });
    } catch (e) {
      // تجاهل الأخطاء في التحديث التلقائي
    }
  }

  void _showNewRequestNotification(int newRequestsCount) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notification_important,
                color: const Color.fromRGBO(255, 255, 255, 1),
                size: 16.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'طلبات رحلة جديدة! 🚨',
                    style: boldTextStyle(color: Colors.white, size: 14),
                  ),
                  Text(
                    'لديك $newRequestsCount طلب${newRequestsCount > 1 ? 'ات' : ''} جديد${newRequestsCount > 1 ? 'ة' : ''} تحتاج موافقتك',
                    style: secondaryTextStyle(color: Colors.white, size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            _tabController?.animateTo(0);
          },
        ),
      ),
    );
  }

  void _monitorCompletedRides() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_tabController?.index == 0 || _tabController?.index == 1) {
        setState(() {
          tabData[PENDING]?.removeWhere((ride) =>
              (ride.status == COMPLETED &&
                  ride.driverId == sharedPref.getInt(USER_ID)) ||
              (ride.status == CANCELED &&
                  ride.driverId == sharedPref.getInt(USER_ID)));
          tabData['active']?.removeWhere((ride) =>
              (ride.status == COMPLETED &&
                  ride.driverId == sharedPref.getInt(USER_ID)) ||
              (ride.status == CANCELED &&
                  ride.driverId == sharedPref.getInt(USER_ID)));
        });
      }
    });
  }

  void init() async {
    afterBuildCreated(() {
      refreshData();
      _monitorCompletedRides();
    });
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() {
      currentPage = 1;
      isLoading = true;
    });
    await fetchRideRequests();
  }

  Future<void> fetchRideRequests() async {
    if (!mounted || _tabController == null) return;

    try {
      String currentStatus = riderStatus[_tabController!.index];

      // تعديل حالة الطلب في API حسب التاب المحدد
      String apiStatus;
      if (currentStatus == COMPLETED || currentStatus == CANCELED) {
        // للطلبات المكتملة والملغية، نطلب فقط الحالة المحددة
        apiStatus = currentStatus;
      } else if (currentStatus == 'active') {
        // للطلبات النشطة، نجلب كل الحالات ثم نفلتر لاحقاً
        apiStatus = '';
      } else {
        // للطلبات الجديدة وغيرها
        apiStatus = currentStatus;
      }

      final response = await getRiderRequestList(
        page: currentPage,
        status: apiStatus,
        driverId: sharedPref.getInt(USER_ID),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        currentPage = response.pagination?.currentPage ?? 1;
        totalPage = response.pagination?.totalPages ?? 1;

        List<RiderModel> newData = response.data ?? [];

        // تطبيق الفلترة حسب نوع التاب
        if (currentStatus == PENDING) {
          // عرض الطلبات الجديدة فقط التي لم يتم قبولها من أي سائق
          newData = newData
              .where((ride) =>
                  (ride.status == PENDING ||
                      ride.status == NEW_RIDE_REQUESTED) &&
                  ride.driverId == null)
              .toList();
        } else if (currentStatus == 'active') {
          // الطلبات النشطة للسائق الحالي فقط
          newData = newData
              .where((ride) =>
                  (ride.status == ACCEPTED ||
                      ride.status == ARRIVING ||
                      ride.status == ARRIVED ||
                      ride.status == IN_PROGRESS ||
                      ride.status == ACTIVE) &&
                  ride.driverId == sharedPref.getInt(USER_ID))
              .toList();
        } else if (currentStatus == COMPLETED) {
          // الطلبات المكتملة للسائق الحالي فقط
          newData = newData
              .where((ride) =>
                  ride.status == COMPLETED &&
                  ride.driverId == sharedPref.getInt(USER_ID))
              .toList();

          // ترتيب الطلبات المكتملة من الأحدث للأقدم
          newData
              .sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        } else if (currentStatus == CANCELED) {
          // الطلبات الملغية للسائق الحالي فقط
          newData = newData
              .where((ride) =>
                  ride.status == CANCELED &&
                  ride.driverId == sharedPref.getInt(USER_ID))
              .toList();

          // ترتيب الطلبات الملغية من الأحدث للأقدم
          newData
              .sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        }

        if (currentPage == 1) {
          tabData[currentStatus] = newData;
        } else {
          tabData[currentStatus]?.addAll(newData);
        }

        // تحديث عداد الطلبات الجديدة
        if (currentStatus == PENDING) {
          _lastPendingCount = tabData[PENDING]?.length ?? 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HomeScreenAppBar(),
          Container(
            margin: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              dividerHeight: 0,
              padding: EdgeInsets.all(4.r),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: boldTextStyle(color: Colors.white, size: 10),
              unselectedLabelStyle: primaryTextStyle(size: 10),
              isScrollable: true,
              tabs: [
                _buildTab(PENDING),
                _buildTab('active'),
                _buildTab(COMPLETED),
                _buildTab(CANCELED),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTabContent(PENDING),
                _buildTabContent('active'),
                _buildTabContent(COMPLETED),
                _buildTabContent(CANCELED),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTab(String status) {
    int count = tabData[status]?.length ?? 0;
    bool isCurrentTab = _tabController?.index == riderStatus.indexOf(status);

    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getTabTitle(status)),
            if (count > 0 && isCurrentTab)
              Container(
                margin: EdgeInsets.only(right: 4.w),
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: boldTextStyle(size: 8, color: primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String status) {
    List<RiderModel> currentData = tabData[status] ?? [];

    return RefreshIndicator(
      onRefresh: refreshData,
      color: primaryColor,
      child: Stack(
        children: [
          if (currentData.isEmpty && !isLoading) _buildEmptyState(status),
          if (currentData.isNotEmpty) _buildRidesList(currentData),
          if (isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildRidesList(List<RiderModel> data) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: data.length + (isLoading ? 1 : 0),
        controller: scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemBuilder: (context, index) {
          if (index == data.length) {
            return _buildLoadingIndicator();
          }
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: modernRideCard(data: data[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEmptyIcon(status),
              size: 64.r,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _getEmptyMessage(status),
            style: boldTextStyle(size: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            _getEmptySubMessage(status),
            style: secondaryTextStyle(size: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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

  Widget? _buildFloatingActionButton() {
    int pendingCount = tabData[PENDING]?.length ?? 0;
    if (_tabController?.index != 0 && pendingCount > 0) {
      return FloatingActionButton.extended(
        onPressed: () => _tabController?.animateTo(0),
        backgroundColor: Colors.orange,
        icon: Icon(Icons.pending_actions, color: Colors.white),
        label: Text(
          'طلبات تحتاج موافقة ($pendingCount)',
          style: boldTextStyle(color: Colors.white, size: 12),
        ),
        elevation: 8,
      );
    }
    return null;
  }

  String _getTabTitle(String status) {
    switch (status) {
      case PENDING:
        return 'طلبات جديدة';
      case 'active':
        return 'طلبات جارية';
      case COMPLETED:
        return changeStatusText(COMPLETED);
      case CANCELED:
        return changeStatusText(CANCELED);
      case 'all':
        return 'الكل';
      default:
        return changeStatusText(status);
    }
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case PENDING:
        return Icons.pending_actions;
      case 'active':
        return Icons.directions_car;
      case COMPLETED:
        return Icons.check_circle_outline;
      case CANCELED:
        return Icons.cancel_outlined;
      case 'all':
        return Icons.inbox_outlined;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case PENDING:
        return 'لا توجد طلبات جديدة';
      case 'active':
        return 'لا توجد رحلات جارية';
      case COMPLETED:
        return 'لا توجد رحلات مكتملة لك';
      case CANCELED:
        return 'لا توجد رحلات ملغية لك';
      case 'all':
        return 'لا توجد طلبات';
      default:
        return 'لا توجد طلبات في هذا القسم';
    }
  }

  String _getEmptySubMessage(String status) {
    switch (status) {
      case PENDING:
        return 'ستظهر الطلبات الجديدة التي تحتاج موافقتك هنا\nتأكد من تفعيل الإشعارات لتلقي التنبيهات';
      case 'active':
        return 'الرحلات المقبولة والجارية ستظهر هنا\nيمكنك متابعة حالة رحلاتك النشطة';
      case COMPLETED:
        return 'سجل رحلاتك المكتملة بنجاح\nيمكنك مراجعة تفاصيل رحلاتك السابقة التي أنجزتها';
      case CANCELED:
        return 'رحلاتك الملغية ستظهر هنا\nيمكنك مراجعة أسباب إلغاء رحلاتك';
      case 'all':
        return 'جميع طلبات الرحلات ستظهر هنا\nيمكنك تصفح كامل سجل رحلاتك';
      default:
        return 'لا توجد بيانات متاحة حالياً';
    }
  }

  Widget modernRideCard({required RiderModel data}) {
    bool isPending = data.status == PENDING;
    bool isCompleted = data.status == COMPLETED;
    bool isCanceled = data.status == CANCELED;
    bool isAccepted = data.status == ACCEPTED;
    bool isNewRequest = data.status == NEW_RIDE_REQUESTED;
    bool isArriving = data.status == ARRIVING;
    bool isArrived = data.status == ARRIVED;
    bool isInProgress = data.status == IN_PROGRESS;
    bool isActive = data.status == ACTIVE;

    bool showActionButtons =
        isPending || isNewRequest || (isAccepted && data.startTime == null);

    bool isActiveRide =
        isAccepted || isArriving || isArrived || isInProgress || isActive;

    Color statusColor = isPending || isNewRequest
        ? Colors.orange
        : isCompleted
            ? Colors.green
            : isAccepted
                ? Colors.blue
                : isArriving
                    ? Colors.purple
                    : isArrived
                        ? Colors.indigo
                        : isInProgress || isActive
                            ? Colors.teal
                            : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: showActionButtons
            ? Border.all(color: Colors.orange.withOpacity(0.3), width: 2)
            : isActiveRide
                ? Border.all(color: statusColor.withOpacity(0.3), width: 2)
                : null,
      ),
      child: InkWell(
        onTap: () {
          if (!isCanceled) {
            launchScreen(
              context,
              RideDetailScreen(orderId: data.id!),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            );
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showActionButtons)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.red.withOpacity(0.1)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notification_important,
                          color: Colors.white,
                          size: 16.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🚨 طلب رحلة جديد',
                              style:
                                  boldTextStyle(size: 14, color: Colors.orange),
                            ),
                            Text(
                              'يتطلب موافقتك للمتابعة',
                              style: secondaryTextStyle(
                                  size: 12, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'عاجل',
                          style: boldTextStyle(size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isActiveRide && !showActionButtons)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.05)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAccepted
                              ? Icons.check_circle
                              : isArriving
                                  ? Icons.directions_car
                                  : isArrived
                                      ? Icons.location_on
                                      : Icons.play_arrow,
                          color: Colors.white,
                          size: 16.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAccepted
                                  ? '✅ رحلة مقبولة'
                                  : isArriving
                                      ? '🚗 في الطريق إليك'
                                      : isArrived
                                          ? '📍 وصل السائق'
                                          : '🚀 رحلة جارية',
                              style:
                                  boldTextStyle(size: 14, color: statusColor),
                            ),
                            Text(
                              isAccepted
                                  ? 'تم قبول الطلب - ابدأ الرحلة'
                                  : isArriving
                                      ? 'السائق في الطريق إلى نقطة الانطلاق'
                                      : isArrived
                                          ? 'السائق وصل - يمكن بدء الرحلة'
                                          : 'الرحلة قيد التنفيذ حالياً',
                              style: secondaryTextStyle(
                                  size: 12,
                                  color: statusColor.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      if (isActiveRide)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'نشط',
                            style: boldTextStyle(size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _getStatusText(data.status.validate()),
                          style: boldTextStyle(
                            size: 12,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (isActiveRide)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'مباشر',
                                style: boldTextStyle(
                                    size: 10, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '#${data.id}',
                          style: boldTextStyle(size: 12, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (data.riderName != null || data.riderContactNumber != null)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: data.riderProfileImage != null
                            ? NetworkImage(data.riderProfileImage!)
                            : null,
                        child: data.riderProfileImage == null
                            ? Icon(Icons.person,
                                color: primaryColor, size: 20.r)
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.riderName != null)
                              Text(
                                data.riderName!,
                                style: boldTextStyle(size: 14),
                              ),
                            if (data.riderContactNumber != null)
                              Text(
                                data.riderContactNumber!,
                                style: secondaryTextStyle(size: 12),
                              ),
                          ],
                        ),
                      ),
                      if (data.riderContactNumber != null && !isCanceled)
                        InkWell(
                          onTap: () async {
                            final Uri phoneUri =
                                Uri.parse('tel:${data.riderContactNumber}');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.phone,
                              color: Colors.green,
                              size: 16.r,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 16.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نقطة الانطلاق',
                                style: secondaryTextStyle(size: 10),
                              ),
                              Text(
                                data.startAddress.validate(),
                                style: primaryTextStyle(size: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          SizedBox(width: 14.w),
                          SizedBox(
                            height: 20.h,
                            child: DottedLine(
                              direction: Axis.vertical,
                              lineLength: double.infinity,
                              lineThickness: 2,
                              dashLength: 3,
                              dashColor: primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 16.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الوجهة',
                                style: secondaryTextStyle(size: 10),
                              ),
                              Text(
                                data.endAddress.validate(),
                                style: primaryTextStyle(size: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.access_time,
                      label: 'التاريخ',
                      value: printDate(data.createdAt.validate()),
                      color: Colors.blue,
                    ),
                  ),
                  if (data.distance != null)
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.straighten,
                        label: 'المسافة',
                        value: '${data.distance} ${data.distanceUnit ?? 'كم'}',
                        color: Colors.purple,
                      ),
                    ),
                  if (data.totalAmount != null)
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.payments,
                        label: 'المبلغ',
                        value: '${data.totalAmount} ر.س',
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              if (showActionButtons) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.05),
                        Colors.red.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pending_actions,
                              color: Colors.orange, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'اتخذ قرارك الآن - طلب في انتظار الموافقة',
                              style: boldTextStyle(
                                  size: 13, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showConfirmDialog(
                                context,
                                'رفض الطلب',
                                'هل أنت متأكد من رفض هذا الطلب؟\nلن تتمكن من التراجع عن هذا القرار.',
                                () => handleRideRequest(data, false),
                                Colors.red,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: BorderSide(
                                      color: Colors.red.withOpacity(0.5),
                                      width: 2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.cancel,
                                      size: 24.r, color: Colors.red),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'رفض',
                                    style: boldTextStyle(
                                        size: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _showConfirmDialog(
                                context,
                                'قبول الطلب',
                                'هل أنت متأكد من قبول هذا الطلب؟\nسيتم إشعار العميل فوراً.',
                                () => handleRideRequest(data, true),
                                Colors.green,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                shadowColor: Colors.green.withOpacity(0.5),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 28.r, color: Colors.white),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'قبول الطلب',
                                    style: boldTextStyle(
                                        size: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8.r),
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(height: 4.h),
          Text(
            label,
            style: secondaryTextStyle(size: 10),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: boldTextStyle(size: 11, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: boldTextStyle(size: 16),
          ),
          content: Text(
            message,
            style: primaryTextStyle(size: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: primaryTextStyle(size: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'تأكيد',
                style: boldTextStyle(size: 14, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case PENDING:
        return 'في الانتظار';
      case NEW_RIDE_REQUESTED:
        return 'طلب جديد';
      case ACCEPTED:
        return 'مقبول';
      case ARRIVING:
        return 'في الطريق';
      case ARRIVED:
        return 'وصل';
      case IN_PROGRESS:
        return 'قيد التنفيذ';
      case ACTIVE:
        return 'نشط';
      case COMPLETED:
        return 'مكتمل';
      case CANCELED:
        return 'ملغي';
      default:
        return changeStatusText(status);
    }
  }

  Future<void> handleRideRequest(RiderModel ride, bool isAccept) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(width: 16.w),
              Text(
                isAccept ? 'جاري قبول الطلب...' : 'جاري رفض الطلب...',
                style: primaryTextStyle(size: 14),
              ),
            ],
          ),
        ),
      );

      Map req = {
        "id": ride.id,
        if (isAccept) "driver_id": sharedPref.getInt(USER_ID),
        "is_accept": isAccept ? "1" : "0",
      };

      await rideRequestResPond(request: req).then((value) {
        Navigator.of(context).pop();

        setState(() {
          tabData[PENDING]?.removeWhere((item) => item.id == ride.id);
          tabData['active']?.removeWhere((item) => item.id == ride.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isAccept ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Text(
                  isAccept ? "تم قبول الطلب بنجاح" : "تم رفض الطلب",
                  style: boldTextStyle(color: Colors.white, size: 14),
                ),
              ],
            ),
            backgroundColor: isAccept ? Colors.green : Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );

        if (isAccept) {
          Future.delayed(Duration(seconds: 1), () {
            _tabController?.animateTo(1);
          });
        }

        Future.delayed(Duration(seconds: 2), () {
          refreshData();
        });
      }).catchError((error) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'حدث خطأ: ${error.toString()}',
                    style: boldTextStyle(color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      });
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'حدث خطأ غير متوقع: ${e.toString()}',
                  style: boldTextStyle(color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
