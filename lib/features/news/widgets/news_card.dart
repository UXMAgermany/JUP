import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/widgets/new_badge.dart';
import 'package:jup/shared/widgets/text.dart';

class NewsCard extends StatelessWidget {
  final String header;
  final String? subhead;
  final String text;
  final String date;
  final String? author;
  final NewsCategory category;
  final bool showMedia;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isNew;

  const NewsCard({
    super.key,
    required this.header,
    this.subhead,
    required this.text,
    required this.date,
    this.author,
    required this.category,
    this.showMedia = true,
    this.imageUrl,
    this.onTap,
    this.isNew = false,
  });

  String _getCategoryLabel() {
    switch (category) {
      case NewsCategory.sport:
        return 'Sport';
      case NewsCategory.music:
        return 'Musik';
      case NewsCategory.events:
        return 'Events';
      case NewsCategory.food:
        return 'Essen';
      case NewsCategory.gaming:
        return 'Gaming';
      case NewsCategory.diy:
        return 'DIY';
      case NewsCategory.other:
        return 'Sonstiges';
    }
  }

  String _getPlaceholderBanner(bool isDarkMode) {
    final theme = isDarkMode ? 'dark' : 'light';
    switch (category) {
      case NewsCategory.diy:
        return 'assets/banners/placeholder_diy_$theme.svg';
      case NewsCategory.sport:
        return 'assets/banners/placeholder_sport_$theme.svg';
      case NewsCategory.music:
        return 'assets/banners/placeholder_music_$theme.svg';
      case NewsCategory.events:
        return 'assets/banners/placeholder_event_$theme.svg';
      case NewsCategory.food:
        return 'assets/banners/placeholder_food_$theme.svg';
      case NewsCategory.gaming:
        return 'assets/banners/placeholder_gaming_$theme.svg';
      case NewsCategory.other:
        return 'assets/banners/placeholder_other_$theme.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media section
            if (showMedia)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImage(context, isDarkMode),
              ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Chip(
                    label: LabelLarge(
                      text: _getCategoryLabel(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                  ),
                  SizedBox(height: 16),
                  // Title
                  InlineNewBadgeTitle(
                    text: header,
                    isNew: isNew,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Subtitle
                  ...[
                    SizedBox(height: 4),
                    BodyMedium(
                      text: subhead ?? text,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                  SizedBox(height: 4),
                  // Author and date row
                  Row(
                    children: [
                      if (author != null) ...[
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        BodySmall(
                          text: author!,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        BodySmall(
                          text: ' | ',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                      BodySmall(
                        text: date,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDarkMode) {
    const imageHeight = 150.0;

    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: imageHeight,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => LayoutBuilder(
          builder: (context, constraints) {
            return ClipRect(
              child: SizedBox(
                width: constraints.maxWidth,
                height: imageHeight,
                child: Transform.scale(
                  scale: 1.2,
                  child: SvgPicture.asset(
                    _getPlaceholderBanner(isDarkMode),
                    fit: BoxFit.cover,
                    width: constraints.maxWidth,
                    height: imageHeight,
                  ),
                ),
              ),
            );
          },
        ),
        maxHeightDiskCache: 450,
        maxWidthDiskCache: 900,
        memCacheHeight: 450,
        memCacheWidth: 900,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    // // Show placeholder if no image URL

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: imageHeight,
            child: Transform.scale(
              scale: 1.2, // Slight scale to ensure no gaps
              child: SvgPicture.asset(
                _getPlaceholderBanner(isDarkMode),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: imageHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}
