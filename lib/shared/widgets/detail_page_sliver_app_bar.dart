import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailPageSliverAppBar extends StatelessWidget {
  final String? imageUrl;
  final String placeholderAssetPath;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;
  final bool isDarkMode;
  final double expandedHeight;

  const DetailPageSliverAppBar({
    super.key,
    this.imageUrl,
    required this.placeholderAssetPath,
    required this.onBackPressed,
    required this.onSharePressed,
    required this.isDarkMode,
    this.expandedHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark, // Android
        statusBarBrightness: isDarkMode
            ? Brightness.dark
            : Brightness.light, // iOS
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: onBackPressed,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Platform.isIOS ? Icons.ios_share : Icons.share,
                color: Colors.white,
              ),
              onPressed: onSharePressed,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                maxHeightDiskCache: 900,
                maxWidthDiskCache: 1200,
                memCacheHeight: 900,
                memCacheWidth: 1200,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => ClipRect(
                  child: Transform.scale(
                    scale: 1.3,
                    child: SvgPicture.asset(
                      placeholderAssetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : ClipRect(
                child: Transform.scale(
                  scale: 1.3, // Slight scale to ensure no gaps
                  child: SvgPicture.asset(
                    placeholderAssetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
      ),
    );
  }
}
