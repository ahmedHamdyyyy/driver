import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHorizontalSpace extends StatelessWidget {
  const ResponsiveHorizontalSpace(
    this.width, {
    super.key,
  });
  final double width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width.w);
  }
}
