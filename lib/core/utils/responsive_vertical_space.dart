import 'package:flutter/widgets.dart';

class ResponsiveVerticalSpace extends StatelessWidget {
  const ResponsiveVerticalSpace(
    this.height, {
    super.key,
  });
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
