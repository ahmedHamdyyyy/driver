import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_driver/core/app_routes/navigation_service.dart';
import 'package:taxi_driver/core/app_routes/router_names.dart';
import 'package:taxi_driver/core/widget/shared/custom_search_field.dart';
import 'package:taxi_driver/screens/MainScreen.dart';

import '../../screens/DashboardScreen.dart';
import '../../screens/RidesListScreen.dart';
import '../../utils/Extensions/app_common.dart';

class TransformedSearchField extends StatelessWidget {
  final String hintText;
  const TransformedSearchField({super.key, this.hintText = "إلي أين ؟"});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -20.h),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(),
              ));
          //launchScreen(context, TripDetailsScreen());
          //NavigationService.pushNamed(RouterNames.tripDetailsMap);
        },
        child: AbsorbPointer(
            absorbing: true, child: CustomSearchField(hintText: hintText)),
      ),
    );
  }
}
