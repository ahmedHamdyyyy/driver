import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CustomRatingWidget extends StatelessWidget {
  const CustomRatingWidget({
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
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      ratingWidget: RatingWidget(
        half: const Icon(Icons.star, color: Colors.amber),
        full: const Icon(Icons.star, color: Colors.amber),
        empty: const Icon(Icons.star_border, color: Colors.amber),
      ),
      onRatingUpdate: (rating) {
        print(rating);
      },
    );
  }
}
