import 'package:flutter/material.dart';
import 'package:taxi_driver/core/utils/responsive_vertical_space.dart';
import 'package:taxi_driver/core/widget/buttons/app_buttons.dart';
import 'package:taxi_driver/core/widget/rating/widgets/popup/driver_rating_list_tile.dart';
import 'package:taxi_driver/core/widget/rating/widgets/popup/rating_widget.dart';
//import 'package:taxi_driver/core/widget/shared/comments_field.dart';

void ratePopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        surfaceTintColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const DriverRatingListTile(),
                const ResponsiveVerticalSpace(24),
                const CustomRatingWidget(
                  isReadOnly: false,
                ),
                const ResponsiveVerticalSpace(24),
                const Text(
                  'اطرق تعليق',
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const ResponsiveVerticalSpace(16),
                // const CommentsField(),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                    title: 'ارسال',
                    onPressed: () {
                      Navigator.pop(context);
                    })
              ],
            )),
      );
    },
  );
}
