import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievement_check.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/features/news/widgets/news_card.dart';
import 'package:jup/features/news/widgets/news_content_blocks.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:jup/shared/services/share_service.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/utils/view_count_formatter.dart';
import 'package:jup/shared/widgets/detail_page_sliver_app_bar.dart';
import 'package:jup/shared/widgets/group_scope_meta.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';

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
  late int _displayViewCount;
  bool _viewCounted = false;
  String? _myRating;

  @override
  void initState() {
    super.initState();
    _displayViewCount = widget.newsEntry.viewCount;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      ref
          .read(newsControllerProvider)
          .fetchRating(widget.newsEntry.documentId, auth.user?.documentId)
          .then((rating) {
        if (mounted) setState(() => _myRating = rating);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewCounted) return;
      // incrementViewCount nutzt useUserAuth — ausgeloggt schlägt der Call
      // serverseitig fehl, daher auch den optimistischen lokalen Increment
      // überspringen (Konsistenz mit surveys_overview_page).
      if (!ref.read(authProvider).isAuthenticated) return;
      _viewCounted = true;
      setState(() {
        _displayViewCount++;
      });
      ref
          .read(newsControllerProvider)
          .incrementViewCount(widget.newsEntry.documentId);
      ref
          .read(newsListProvider.notifier)
          .incrementViewCount(widget.newsEntry.documentId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Exclusive thumbs toggle with optimistic UI. On success, runs the
  /// achievement check for "Meinungsmutig".
  Future<void> _onRate(String value) async {
    final previous = _myRating;
    final newValue = previous == value ? null : value; // tap active → clear
    setState(() => _myRating = newValue);
    try {
      await ref
          .read(newsControllerProvider)
          .rate(widget.newsEntry.documentId, newValue);
    } catch (_) {
      if (mounted) setState(() => _myRating = previous);
      return;
    }
    if (newValue != null && mounted) {
      await runAchievementCheck(context, ref, keys: ['allgemein.meinungsmutig']);
    }
  }

  Widget _buildFeedbackSection() {
    final colors = Theme.of(context).colorScheme;
    Widget thumb(IconData icon, String value, String semantic) {
      final selected = _myRating == value;
      return IconButton.filledTonal(
        onPressed: () => _onRate(value),
        icon: Icon(icon),
        isSelected: selected,
        tooltip: semantic,
        style: IconButton.styleFrom(
          foregroundColor: selected ? colors.onPrimary : colors.primary,
          backgroundColor:
              selected ? colors.primary : colors.secondaryContainer,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: colors.surfaceContainer),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleMedium(text: 'Gib uns Feedback!'),
          const SizedBox(height: 4),
          BodyMedium(
            text: 'Wie findest du den Beitrag?',
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              thumb(Icons.thumb_up, 'up', 'Positiv bewerten'),
              const SizedBox(width: 8),
              thumb(Icons.thumb_down, 'down', 'Negativ bewerten'),
            ],
          ),
        ],
      ),
    );
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
    final isJUPAdmin = authState.user?.isJUPAdmin ?? false;
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
            heroTag: 'detail-hero-news-${widget.newsEntry.documentId}',
            onBackPressed: () => context.router.maybePop(),
            onSharePressed: () => ShareService().shareDeepLink(
              context: context,
              deepLink: _deepLinkService.generateNewsLink(
                widget.newsEntry.documentId,
              ),
              title: widget.newsEntry.title,
              contentTypeLabel: 'News-Beitrag',
            ),
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
                              text: widget.newsEntry.category.displayLabel,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.newsEntry.author != null) ...[
                            Icon(
                              Icons.person,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            BodySmall(
                              text: widget.newsEntry.author!,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            BodySmall(
                              text: ' | ',
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                          BodySmall(
                            text: DateFormatHelper.formatDate(
                              widget.newsEntry.createdAt,
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      if (widget.newsEntry.scopeGroupName != null &&
                          widget.newsEntry.scopeGroupName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        GroupScopeMeta(
                          groupName: widget.newsEntry.scopeGroupName,
                        ),
                      ],
                      if (isJUPAdmin) ...[
                        const SizedBox(height: 4),
                        Semantics(
                          label:
                              '${formatViewCount(_displayViewCount)}, nur für Administratoren sichtbar',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                BodySmall(
                                  text: formatViewCount(_displayViewCount),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 4),
                NewsContentBlocks(
                  blocks: widget.newsEntry.contentBlocks,
                  fallbackText: widget.newsEntry.text,
                  heroTagPrefix:
                      'detail-content-news-${widget.newsEntry.documentId}',
                ),
                if (authState.isAuthenticated) ...[
                  const SizedBox(height: 4),
                  _buildFeedbackSection(),
                ],
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
                          date: DateFormatHelper.formatDate(entry.createdAt),
                          author: entry.author,
                          imageUrl: entry.imageUrl,
                          category: entry.category,
                          showMedia: true,
                          viewCount: entry.viewCount,
                          isJUPAdmin: isJUPAdmin,
                          scopeGroupName: entry.scopeGroupName,
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
