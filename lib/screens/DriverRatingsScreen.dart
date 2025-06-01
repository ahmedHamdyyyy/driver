import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../main.dart';
import '../model/DriverRatting.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../core/widget/appbar/home_screen_app_bar.dart';
import 'package:intl/intl.dart' as intl;

class DriverRatingsScreen extends StatefulWidget {
  final int? userId;
  final num? currentRating;
  final int? totalRatings;

  const DriverRatingsScreen({
    Key? key,
    this.userId,
    this.currentRating,
    this.totalRatings,
  }) : super(key: key);

  @override
  State<DriverRatingsScreen> createState() => _DriverRatingsScreenState();
}

class _DriverRatingsScreenState extends State<DriverRatingsScreen> {
  List<Map<String, dynamic>> ratingDistribution = [
    {'stars': 5, 'count': 0},
    {'stars': 4, 'count': 0},
    {'stars': 3, 'count': 0},
    {'stars': 2, 'count': 0},
    {'stars': 1, 'count': 0},
  ];

  List<DriverRatting> recentReviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      if (widget.userId == null) {
        throw 'User ID is required';
      }

      final ratings = await getDriverRatings(driverId: widget.userId!);

      // Process ratings distribution
      for (var rating in ratings) {
        final stars = rating.rating?.round() ?? 0;
        if (stars > 0 && stars <= 5) {
          ratingDistribution[5 - stars]['count']++;
        }
      }

      // Get recent reviews with comments
      recentReviews = ratings
          .where((r) => r.comment != null && r.comment!.isNotEmpty)
          .toList();
      recentReviews
          .sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  Widget _buildRatingOverview() {
    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    widget.currentRating?.toStringAsFixed(1) ?? '0.0',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < (widget.currentRating ?? 0).floor()
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 24,
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${recentReviews.length} تقييم',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Column(
            children: ratingDistribution.map((data) {
              final percentage = recentReviews.isNotEmpty
                  ? (data['count'] / recentReviews.length * 100)
                  : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${data['stars']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
    if (recentReviews.isEmpty) {
      return Center(
        child: Text(
          'لا توجد تقييمات حتى الآن',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recentReviews.length,
      itemBuilder: (context, index) {
        final review = recentReviews[index];
        final date = review.createdAt != null
            ? intl.DateFormat('yyyy/MM/dd')
                .format(DateTime.parse(review.createdAt!))
            : '';

        return Container(
          margin: EdgeInsets.only(bottom: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'راكب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        review.rating?.toString() ?? '0',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                review.comment ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: () => init(),
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
                            'تقييمات السائق',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildRatingOverview(),
                          SizedBox(height: 24),
                          Text(
                            'آخر التقييمات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildRecentReviews(),
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
