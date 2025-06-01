import 'package:flutter/material.dart';
import 'package:taxi_driver/core/constant/app_icons.dart';
import 'package:taxi_driver/main.dart';

class UserImage extends StatelessWidget {
  const UserImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String? profileImage = appStore.userProfile;

    return Container(
      width: 45,
      height: 45,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: profileImage != null && profileImage.isNotEmpty
              ? NetworkImage(profileImage) as ImageProvider
              : AssetImage(AppIcons.user),
          fit: BoxFit.fill,
        ),
        shape: const OvalBorder(),
      ),
    );
  }
}
