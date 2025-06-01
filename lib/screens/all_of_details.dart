import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_driver/core/app_bar/search_field.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/appbar/home_screen_app_bar.dart';
import 'package:taxi_driver/screens/EarningScreen.dart';
import 'package:taxi_driver/screens/RidesListScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../utils/Constants.dart';
import 'MainScreen.dart';
import 'DriverRatingsScreen.dart';

class AllOfDetails extends StatefulWidget {
  const AllOfDetails({super.key});

  @override
  State<AllOfDetails> createState() => _AllOfDetailsState();
}

class _AllOfDetailsState extends State<AllOfDetails> {
  UserDetailModel? userDetail;
  int totalCompletedRides = 0;
  num totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    try {
      final userId = sharedPref.getInt(USER_ID) ?? 0;
      if (userId == 0) {
        throw Exception('User ID not found');
      }

      // Fetch user details
      userDetail = await getUserDetail(userId: userId);

      // Get total completed rides count for this driver
      final completedRides = await getRiderRequestList(
        page: 1,
        status: COMPLETED,
        driverId: userId,
      );
      if (completedRides.data != null) {
        totalCompletedRides = completedRides.data!
            .where(
                (ride) => ride.driverId == userId && ride.status == COMPLETED)
            .length;
      }

      // Get total earnings
      final earnings = await earningList(req: {"type": "report"});
      if (earnings.totalEarnings != null) {
        totalEarnings = earnings.totalEarnings!;
      }

      setState(() {});
    } catch (e) {
      log(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/carr.jpg',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
            Container(
              width: double.infinity,
              height: 160,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'كلما زادت تقييماتك الإيجابية',
                    style: boldTextStyle(color: Colors.white, size: 16),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    'زادت فرصتك في الحصول على',
                    style: boldTextStyle(color: Colors.white, size: 16),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    'المزيد من الركاب',
                    style: boldTextStyle(color: Colors.white, size: 16),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Widget icon,
  }) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: boldTextStyle(color: Colors.white, size: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          icon,
          SizedBox(height: 8),
          Text(
            value,
            style: boldTextStyle(color: Colors.white, size: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: secondaryTextStyle(
              color: Colors.white.withOpacity(0.8),
              size: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeScreenAppBar(),
            /*  const TransformedSearchField(
              hintText: "ابحث عن ما تريد",
            ), */
            const ResponsiveVerticalSpace(10),
            _buildBanner(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مزايا الكابتن',
                    style: boldTextStyle(size: 16),
                  ),
                  SizedBox(height: 16),
                  GridView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverRatingsScreen(
                                userId: userDetail?.data?.id,
                                currentRating: userDetail?.data?.rating,
                                totalRatings:
                                    0, // This will be updated from the API
                              ),
                            ),
                          );
                        },
                        child: _buildStatCard(
                          title: 'التقييم',
                          value: '${userDetail?.data?.rating ?? 0} تقييم',
                          subtitle:
                              'هذا الذي من خلال تقييم المستخدمين لك في الشهر',
                          icon: SvgPicture.asset(
                            'assets/icons/star 1.svg',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                      _buildStatCard(
                        title: 'المشاركات',
                        value: '75%',
                        subtitle: 'هذا الذي من خلال نشاطك في الشهر',
                        icon: SvgPicture.asset(
                          'assets/icons/Group.svg',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          launchScreen(context, EarningScreen(),
                              pageRouteAnimation: PageRouteAnimation.Slide);
                        },
                        child: _buildStatCard(
                          title: 'الربح',
                          value:
                              '${totalEarnings.toStringAsFixed(digitAfterDecimal)}',
                          subtitle: 'هذا الذي من خلال نشاطك في الشهر',
                          icon: SvgPicture.asset(
                            'assets/icons/money 1.svg',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RidesListScreen(),
                            ),
                          );
                        },
                        child: _buildStatCard(
                          title: 'الرحلات',
                          value: '$totalCompletedRides رحلة',
                          subtitle: 'هذا الذي من خلال نشاطك في الشهر',
                          icon: SvgPicture.asset(
                            'assets/icons/car (2) 1.svg',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
