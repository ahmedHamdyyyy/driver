import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SmallRatingWidget extends StatelessWidget {
  const SmallRatingWidget({
    super.key,
    required this.isReadOnly,
  });
  final bool isReadOnly;
  @override
  Widget build(BuildContext context) {
    return RatingBar(
      ignoreGestures: isReadOnly,
      unratedColor: Colors.amber,
      initialRating: 0,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: 18.r,
      itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
      ratingWidget: RatingWidget(
        half: const Icon(
          Icons.star,
          color: Colors.amber,
          size: 5,
        ),
        full: const Icon(
          Icons.star,
          color: Colors.amber,
          size: 5,
        ),
        empty: const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 5,
        ),
      ),
      onRatingUpdate: (rating) {
        print(rating);
      },
    );
  }
}
