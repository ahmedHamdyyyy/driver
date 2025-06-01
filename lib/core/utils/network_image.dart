import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage({
    super.key,
    this.errorWidget,
    required this.imageUrl,
    this.imageBuilder,
    this.width,
    this.height,
  });
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final Widget Function(BuildContext, ImageProvider<Object>)? imageBuilder;
  final String imageUrl;
  final double? width, height;
  @override
  Widget build(BuildContext context) {
    final isSvg = imageUrl.contains('.svg');
    return isSvg
        ? SvgPicture.network(imageUrl)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            errorWidget: errorWidget,
            imageBuilder: imageBuilder,
          );
  }
}
