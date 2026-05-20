import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/features/news/widgets/news_card.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/detail_page_sliver_app_bar.dart';
import 'package:jup/shared/widgets/expandable_text_section.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class NewsDetailPage extends ConsumerStatefulWidget {
  final NewsEntry newsEntry;

  const NewsDetailPage({super.key, required this.newsEntry});

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getPlaceholderBanner(NewsCategory category, bool isDarkMode) {
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
    final authState = ref.watch(authProvider);
    final newsAsyncValue = ref.watch(newsListProvider);
    final brightness = Theme.of(context).brightness;
    bool isDarkMode = brightness == Brightness.dark;

    // Get other news for the "News" section at the bottom
    final otherNews = newsAsyncValue.maybeWhen(
      data: (allNews) => allNews
          .where((entry) => entry.documentId != widget.newsEntry.documentId)
          .take(3)
          .toList(),
      orElse: () => <NewsEntry>[],
    );

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          DetailPageSliverAppBar(
            imageUrl: widget.newsEntry.imageUrl,
            placeholderAssetPath: _getPlaceholderBanner(
              widget.newsEntry.category,
              isDarkMode,
            ),
            isDarkMode: isDarkMode,
            onBackPressed: () => context.router.maybePop(),
            onSharePressed: () async {
              final deepLink = _deepLinkService.generateNewsLink(
                widget.newsEntry.documentId,
              );
              await Share.share(deepLink);
            },
          ),

          // Main content section
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Chip(
                            label: LabelLarge(
                              text: widget.newsEntry.getCategoryName(),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      TitleMedium(text: widget.newsEntry.title),

                      // Subtitle if available
                      if (widget.newsEntry.subTitle != null)
                        BodyMedium(
                          text: widget.newsEntry.subTitle!,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ).withPaddingY(8),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (widget.newsEntry.author != null) ...[
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        BodySmall(
                          text: widget.newsEntry.author!,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        BodySmall(
                          text: ' | ',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                      BodySmall(
                        text: DateFormatHelper.formatDate(
                          widget.newsEntry.createdAt,
                        ),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                ExpandableTextSection(text: widget.newsEntry.text),
              ],
            ),
          ),

          if (otherNews.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // Related news section
          if (otherNews.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleLargeEmphasized(text: 'Weitere News'),
                    SizedBox(height: 16),
                    ...otherNews.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NewsCard(
                          header: entry.title,
                          subhead: entry.subTitle,
                          text: entry.text,
                          date: DateFormatHelper.formatDate(entry.createdAt),
                          author: entry.author,
                          imageUrl: entry.imageUrl,
                          category: entry.category,
                          showMedia: true,
                          onTap: () {
                            if (!authState.isAuthenticated) {
                              LoginRequiredDialog.show(
                                context,
                                message:
                                    'Melde dich an und entdecke alle unsere Inhalte!',
                              );
                              return;
                            }
                            context.router.push(
                              NewsDetailRoute(newsEntry: entry),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ).withPaddingX(16),
              ),
            ),
        ],
      ),
    );
  }
}
