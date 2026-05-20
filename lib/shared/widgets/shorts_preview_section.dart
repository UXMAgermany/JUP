import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/shorts/widgets/shorts_card.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/utils/unseen_sort_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ShortsPreviewSection extends ConsumerWidget {
  final Function(int index) onShortTap;
  final int maxShorts;

  const ShortsPreviewSection({
    super.key,
    required this.onShortTap,
    this.maxShorts = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsyncValue = ref.watch(shortsListProvider);
    final seenPosts = ref.watch(seenPostsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeadlineSmallEmphasized(text: 'Shorts').withPaddingBottom(12),
        shortsAsyncValue.when(
          data: (shortsList) {
            if (shortsList.isEmpty) {
              return EmptyState();
            }

            final sortedShorts = sortWithBadges(shortsList, seenPosts, (e) => e.documentId, (_) => false);
            final displayShorts = sortedShorts.take(maxShorts).toList();

            // Calculate card width based on screen width
            return LayoutBuilder(
              builder: (context, constraints) {
                // Make each card take about 45% of screen width for better scrolling
                final cardWidth = constraints.maxWidth * 0.45;

                return SizedBox(
                  height: cardWidth * (16 / 9) +
                      80, // height based on 9:16 aspect ratio + text space
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayShorts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisibilityDetector(
                          key: Key('short_${displayShorts[index].documentId}'),
                          onVisibilityChanged: (info) {
                            if (info.visibleFraction > 0.5) {
                              ref.read(seenPostsProvider.notifier).markAsSeen(displayShorts[index].documentId);
                            }
                          },
                          child: ShortsCard(
                            shortsEntry: displayShorts[index],
                            isNew: isNewPost(
                              documentId: displayShorts[index].documentId,
                              createdAt: displayShorts[index].createdAt,
                              seenPosts: seenPosts,
                              isLoaded: ref.read(seenPostsProvider.notifier).isLoaded,
                              firstLaunchDate: ref.read(seenPostsProvider.notifier).firstLaunchDate,
                            ),
                            onTap: () => onShortTap(index),
                            initializeVideo:
                                false, // Don't initialize videos in preview
                            autoPlay: false, // Don't autoplay videos
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => ConnectionErrorWidget(
            errorMessage: error.toString(),
            onRetry: () => ref.invalidate(shortsListProvider),
            height: 256,
          ),
        ),
      ],
    );
  }
}
