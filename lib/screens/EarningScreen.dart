import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart' as intl;

import '../components/EarningReportWidget.dart';
import '../components/EarningTodayWidget.dart';
import '../components/EarningWeekWidget.dart';
import '../core/widget/appbar/home_screen_app_bar.dart';
import '../main.dart';
import '../model/EarningListModelWeek.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class EarningScreen extends StatefulWidget {
  @override
  EarningScreenState createState() => EarningScreenState();
}

class EarningScreenState extends State<EarningScreen> {
  EarningListModelWeek? earningListModelWeek;
  List<WeekReport> weekReport = [];

  num totalRideCount = 0;
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num totalCardRide = 0;
  num totalEarnings = 0;
  num todayEarnings = 0;
  num weeklyEarnings = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    try {
      // Get weekly data
      await earningList(req: {"type": "week"}).then((value) {
        totalRideCount = value.totalRideCount ?? 0;
        totalCashRide = value.totalCashRide ?? 0;
        totalWalletRide = value.totalWalletRide ?? 0;
        totalCardRide = value.totalCardRide ?? 0;
        totalEarnings = value.totalEarnings ?? 0;
        weekReport = value.weekReport ?? [];
        weeklyEarnings = value.totalEarnings ?? 0;
      });

      // Get today's data
      await earningList(req: {"type": "today"}).then((value) {
        todayEarnings = value.todayEarnings ?? 0;
      });

      setState(() {});
    } catch (error) {
      log(error.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Widget _buildEarningCard({
    required String title,
    required num amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                amount.toStringAsFixed(digitAfterDecimal),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    final total = totalCashRide + totalWalletRide + totalCardRide;
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SfCircularChart(
        title: ChartTitle(
          text: 'طرق الدفع',
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <CircularSeries>[
          DoughnutSeries<Map<String, dynamic>, String>(
            dataSource: [
              {
                'method': 'نقدي',
                'amount': totalCashRide,
                'color': Colors.green
              },
              {
                'method': 'محفظة',
                'amount': totalWalletRide,
                'color': Colors.blue
              },
              {
                'method': 'بطاقة',
                'amount': totalCardRide,
                'color': Colors.orange
              },
            ],
            pointColorMapper: (data, _) => data['color'],
            xValueMapper: (data, _) => data['method'],
            yValueMapper: (data, _) => data['amount'],
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: TextStyle(fontSize: 12),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '{value} ريال',
          labelStyle: TextStyle(fontSize: 12),
        ),
        title: ChartTitle(
          text: 'الأرباح الأسبوعية',
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          ColumnSeries<WeekReport, String>(
            dataSource: weekReport,
            xValueMapper: (WeekReport report, _) => report.day ?? '',
            yValueMapper: (WeekReport report, _) => report.amount ?? 0,
            pointColorMapper: (WeekReport report, _) => primaryColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: appStore.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: () async => init(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const HomeScreenAppBar(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نظرة عامة',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.3,
                            children: [
                              _buildEarningCard(
                                title: 'أرباح اليوم',
                                amount: todayEarnings,
                                icon: Icons.today,
                                color: Colors.green,
                              ),
                              _buildEarningCard(
                                title: 'أرباح الأسبوع',
                                amount: weeklyEarnings,
                                icon: Icons.date_range,
                                color: Colors.blue,
                              ),
                              _buildEarningCard(
                                title: 'إجمالي الرحلات',
                                amount: totalRideCount,
                                icon: Icons.directions_car,
                                color: Colors.purple,
                                subtitle: 'عدد الرحلات المكتملة',
                              ),
                              _buildEarningCard(
                                title: 'إجمالي الأرباح',
                                amount: totalEarnings,
                                icon: Icons.account_balance_wallet,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          _buildPaymentMethodChart(),
                          SizedBox(height: 24),
                          _buildWeeklyChart(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
