import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/shared/widgets/tappable_network_image.dart';

class DetailPageSliverAppBar extends StatelessWidget {
  final String? imageUrl;
  final String placeholderAssetPath;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;
  final bool isDarkMode;
  final double? expandedHeight;
  final Object? heroTag;

  const DetailPageSliverAppBar({
    super.key,
    this.imageUrl,
    required this.placeholderAssetPath,
    required this.onBackPressed,
    required this.onSharePressed,
    required this.isDarkMode,
    this.expandedHeight,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Hero image follows the same 16:9 ratio as Event/News/Survey cards.
    final effectiveExpandedHeight =
        expandedHeight ?? MediaQuery.of(context).size.width * 9 / 16;

    return SliverAppBar(
      expandedHeight: effectiveExpandedHeight,
      toolbarHeight: 80,
      pinned: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark, // Android
        statusBarBrightness:
            isDarkMode ? Brightness.dark : Brightness.light, // iOS
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackPressed,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
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
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl != null
            ? _buildHeaderImage(context, imageUrl!)
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

  Widget _buildHeaderImage(BuildContext context, String url) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Cache sizes for Retina (3x) at 16:9 in full screen width
      maxHeightDiskCache: 675,
      maxWidthDiskCache: 1200,
      memCacheHeight: 675,
      memCacheWidth: 1200,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => ClipRect(
        child: Transform.scale(
          scale: 1.3,
          child: SvgPicture.asset(placeholderAssetPath, fit: BoxFit.cover),
        ),
      ),
    );

    if (heroTag == null) return image;
    return TappableNetworkImage(
      imageUrl: url,
      heroTag: heroTag!,
      semanticLabel: 'Titelbild',
      child: image,
    );
  }
}
