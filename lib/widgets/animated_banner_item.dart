import 'package:flutter/material.dart';
import 'package:details_app/models/banner_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimatedBannerItem extends StatelessWidget {
  final BannerModel banner;
  const AnimatedBannerItem({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
