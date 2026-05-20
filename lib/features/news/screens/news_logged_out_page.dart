import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/widgets/welcome_header_large.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/widgets/news_card.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/widgets/shorts_preview_section.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';

@RoutePage()
class NewsLoggedOutPage extends ConsumerStatefulWidget {
  const NewsLoggedOutPage({super.key});

  @override
  ConsumerState<NewsLoggedOutPage> createState() => _NewsLoggedOutPageState();
}

class _NewsLoggedOutPageState extends ConsumerState<NewsLoggedOutPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    // Register scroll controller for News tab (index 0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(0, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref.read(scrollControllerProvider.notifier).unregisterController(0);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final newsAsyncValue = ref.watch(newsListProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([const NewsOverviewRoute()]);
      });
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data sources
          await Future.wait([
            ref.read(newsListProvider.notifier).refresh(),
            ref.read(shortsListProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 324,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(background: WelcomeHeaderLarge()),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Shorts section
                  ShortsPreviewSection(
                    onShortTap: (index) {
                      context.router.push(ShortsFeedRoute(initialIndex: index));
                    },
                  ),
                  const SizedBox(height: 16),
                  // News section
                  HeadlineSmallEmphasized(text: 'News').withPaddingBottom(8),
                  // News cards
                  newsAsyncValue.when(
                    data: (newsList) {
                      if (newsList.isEmpty) {
                        return SizedBox(height: 200, child: EmptyState());
                      }
                      // Display up to 3 news items
                      final displayNews = newsList.take(3).toList();
                      return Column(
                        children: displayNews
                            .map(
                              (entry) => RepaintBoundary(
                                child: NewsCard(
                                  header: entry.title,
                                  subhead: entry.subTitle,
                                  text: entry.text,
                                  date: DateFormatHelper.formatDate(
                                    entry.createdAt,
                                  ),
                                  author: entry.author,
                                  imageUrl: entry.imageUrl,
                                  category: entry.category,
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
                                ).withPaddingBottom(8),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => SizedBox(
                        height: 256,
                        child: Stack(
                          children: [
                            // Main content
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(),
                                  const SizedBox(height: 16),
                                  // Message
                                  Text(
                                    error.toString(),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  // Retry Button
                                  Center(
                                    child: FilledButton(
                                      onPressed: () {},
                                      child: const Text('Nochmal probieren'),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(
                                      height: 100), // Space for the star
                                ],
                              ),
                            ),
                            // Sad star illustration - positioned on the right
                            Positioned(
                              bottom: 0,
                              right: -48,
                              child: Image.asset(
                                'assets/banners/sad_star.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        )),
                  ),
                  const SizedBox(height: 80), // Space for bottom nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
