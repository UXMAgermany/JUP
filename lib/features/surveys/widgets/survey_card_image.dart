import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/surveys/models/survey_model.dart';

class SurveyCardImage extends StatefulWidget {
  final SurveyEntry surveyEntry;

  const SurveyCardImage({super.key, required this.surveyEntry});

  @override
  State<SurveyCardImage> createState() => _SurveyCardImageState();
}

class _SurveyCardImageState extends State<SurveyCardImage> {
  bool _imageLoadFailed = false;
  static const _imageHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = isDarkMode ? 'dark' : 'light';
    final placeholderBanner = 'assets/banners/placeholder_vote_$theme.svg';

    return Stack(
      children: [
        Container(
          height: _imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: widget.surveyEntry.imageUrl != null && !_imageLoadFailed
                ? CachedNetworkImage(
                    imageUrl: widget.surveyEntry.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      return Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorWidget: (context, url, error) {
                      debugPrint('Image error for $url: $error');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_imageLoadFailed) {
                          setState(() => _imageLoadFailed = true);
                        }
                      });
                      return const SizedBox.shrink();
                    },
                    maxHeightDiskCache: 360,
                    maxWidthDiskCache: 720,
                    memCacheHeight: 360,
                    memCacheWidth: 720,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRect(
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: _imageHeight,
                          child: Transform.scale(
                            scale: 1.2,
                            child: SvgPicture.asset(
                              placeholderBanner,
                              fit: BoxFit.cover,
                              width: constraints.maxWidth,
                              height: _imageHeight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (widget.surveyEntry.type == SurveyType.election)
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/banners/election_star.svg',
              width: 56,
              height: 56,
            ),
          ),
      ],
    );
  }
}
