import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/features/events/widgets/event_bookmark_button.dart';
import 'package:jup/features/events/widgets/event_participation_button.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/new_badge.dart';
import 'package:jup/shared/widgets/text.dart';

class EventCard extends StatefulWidget {
  final EventEntry event;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onParticipateToggle;
  final bool isParticipating;
  final bool isBookmarked;
  final bool isFullWidth;
  final bool isDisabled;
  final bool isParticipationLoading;
  final bool isPast;
  final bool isNew;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onBookmarkTap,
    this.onParticipateToggle,
    this.isParticipating = false,
    this.isBookmarked = false,
    this.isFullWidth = true,
    this.isDisabled = false,
    this.isParticipationLoading = false,
    this.isPast = false,
    this.isNew = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final cardWidth = widget.isFullWidth ? double.infinity : 300.0;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: widget.isPast ? 0.6 : 1.0,
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: widget.isFullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildImage(context, isDarkMode),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: LabelLarge(
                            text: widget.event.getCategoryName(),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                        ),
                        EventBookmarkButton(
                          isBookmarked: widget.isBookmarked,
                          onTap: widget.onBookmarkTap,
                          isDisabled: widget.isDisabled,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    InlineNewBadgeTitle(
                      text: widget.event.title,
                      isNew: widget.isNew,
                      isPast: widget.isPast,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.event.subTitle != null) ...[
                      SizedBox(height: 4),
                      BodyMedium(
                        text: widget.event.subTitle!,
                        maxLines: widget.isFullWidth ? null : 1,
                        overflow: widget.isFullWidth
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12),
                        SizedBox(width: 4),
                        BodySmall(
                          text: DateFormatHelper.formatDateTime(
                            widget.event.startTime,
                          ),
                        ),
                        if (widget.event.isRepeating()) ...[
                          SizedBox(width: 4),
                          Icon(Icons.autorenew, size: 12),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12),
                        SizedBox(width: 4),
                        Expanded(child: BodySmall(text: widget.event.location)),
                      ],
                    ),
                    SizedBox(height: widget.isFullWidth ? 16 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!widget.isPast)
                          EventParticipationButton(
                            isParticipating: widget.isParticipating,
                            onTap: widget.onParticipateToggle,
                            isLoading: widget.isParticipationLoading,
                            isDisabled: widget.isDisabled,
                          ),
                        Row(
                          children: [
                            BodySmall(
                              text: widget.isPast
                                  ? "${widget.event.participantCount} ${widget.event.participantCount == 1 ? 'war' : 'waren'} dabei"
                                  : "${widget.event.participantCount} ${widget.event.participantCount == 1 ? 'ist' : 'sind'} dabei",
                            ),
                            SizedBox(width: 4),
                            Icon(
                              widget.event.participantCount == 0
                                  ? Icons.sentiment_neutral
                                  : Icons.tag_faces,
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDarkMode) {
    if (widget.event.imageUrl == null || _imageLoadFailed) {
      return _buildPlaceholderImage(context, isDarkMode);
    }

    return CachedNetworkImage(
      imageUrl: widget.event.imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        debugPrint('Loading event image: $url');
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorWidget: (context, url, error) {
        debugPrint('Event image error for $url: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_imageLoadFailed) {
            setState(() => _imageLoadFailed = true);
          }
        });
        return _buildPlaceholderImage(context, isDarkMode);
      },
      // Cache sizes for Retina (3x) at 16:9 in card width
      maxHeightDiskCache: 675,
      maxWidthDiskCache: 1200,
      memCacheHeight: 675,
      memCacheWidth: 1200,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context, bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Transform.scale(
              scale: 1.2,
              child: SvgPicture.asset(
                widget.event.getPlaceholderBanner(isDarkMode),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}
