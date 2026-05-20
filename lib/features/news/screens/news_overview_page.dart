import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/news_filter_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/controllers/wifi_password_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/features/news/widgets/jup_banner.dart';
import 'package:jup/features/news/widgets/news_card.dart';
import 'package:jup/features/news/widgets/wifi_password_banner.dart';
import 'package:jup/features/news/widgets/wifi_password_dismiss_sheet.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/category_dropdown.dart';
import 'package:jup/shared/widgets/shorts_preview_section.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/utils/unseen_sort_helper.dart';

@RoutePage()
class NewsOverviewPage extends ConsumerStatefulWidget {
  const NewsOverviewPage({super.key});

  @override
  ConsumerState<NewsOverviewPage> createState() => _NewsOverviewPageState();
}

class _NewsOverviewPageState extends ConsumerState<NewsOverviewPage> {
  static const _wifiDismissDialogPrefsKey = 'wifiPasswordDismissDialogSkip';
  static const _dismissedWifiPasswordKey = 'dismissedWifiPassword';
  final ScrollController _scrollController = ScrollController();
  bool _isRegistered = false;
  bool _wifiPasswordBannerDismissed = false;
  int? _displayLimit = 5;

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

    // Reset display limit when filters change
    ref.listenManual(newsFilterProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _displayLimit = 5;
        });
      }
    });

    // Listen for WiFi password changes
    ref.listenManual(wifiPasswordProvider, (previous, next) {
      next.whenData((wifiPassword) async {
        final prefs = await SharedPreferences.getInstance();
        final dismissedPassword = prefs.getString(_dismissedWifiPasswordKey);

        // If there's a dismissed password stored and it's different from current, show banner again
        if (dismissedPassword != null &&
            dismissedPassword != wifiPassword.password) {
          // Clear the dismissed password key so banner appears
          await prefs.remove(_dismissedWifiPasswordKey);
          if (mounted) {
            setState(() {
              _wifiPasswordBannerDismissed = false;
            });
          }
        } else if (dismissedPassword != null &&
            dismissedPassword == wifiPassword.password) {
          // Password is the same as dismissed one, keep it hidden
          if (mounted) {
            setState(() {
              _wifiPasswordBannerDismissed = true;
            });
          }
        }
      });
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

  Future<void> _handleWifiPasswordDismiss() async {
    // Check if user has opted out of showing the dialog
    final prefs = await SharedPreferences.getInstance();
    final skipDialog = prefs.getBool(_wifiDismissDialogPrefsKey) ?? false;

    // Get current password to save it
    final wifiPasswordAsync = ref.read(wifiPasswordProvider);
    String? currentPassword;
    wifiPasswordAsync.whenData((wifiPassword) {
      currentPassword = wifiPassword.password;
    });

    if (skipDialog) {
      // Directly dismiss without showing dialog
      setState(() {
        _wifiPasswordBannerDismissed = true;
      });
      // Save the dismissed password
      if (currentPassword != null) {
        await prefs.setString(_dismissedWifiPasswordKey, currentPassword!);
      }
      return;
    }

    // Show confirmation bottom sheet
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) => const WifiPasswordDismissSheet(),
    );

    // Handle result
    if (result != null && result['confirmed'] == true) {
      setState(() {
        _wifiPasswordBannerDismissed = true;
      });

      // Save the dismissed password
      if (currentPassword != null) {
        await prefs.setString(_dismissedWifiPasswordKey, currentPassword!);
      }

      // Save "don't show again" preference if checked
      if (result['dontShowAgain'] == true) {
        await prefs.setBool(_wifiDismissDialogPrefsKey, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedNewsFilters = ref.watch(newsFilterProvider);
    final newsAsyncValue = ref.watch(newsListProvider);
    final seenPosts = ref.watch(seenPostsProvider);
    final wifiPasswordAsyncValue = ref.watch(wifiPasswordProvider);

    // Check if WiFi password changed on every build
    wifiPasswordAsyncValue.whenData((wifiPassword) async {
      final prefs = await SharedPreferences.getInstance();
      final dismissedPassword = prefs.getString(_dismissedWifiPasswordKey);

      if (dismissedPassword != null &&
          dismissedPassword != wifiPassword.password &&
          _wifiPasswordBannerDismissed) {
        // Password changed and banner is currently dismissed, show it again
        await prefs.remove(_dismissedWifiPasswordKey);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _wifiPasswordBannerDismissed = false;
              });
            }
          });
        }
      }
    });

    if (authState.isAuthenticated == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.router.replaceAll([const NewsLoggedOutRoute()]);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String getFilterLabel(NewsCategory filter) {
      switch (filter) {
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(seenPostsProvider.notifier).flushPending();
          setState(() {
            _displayLimit = 5;
          });
          // Refresh all data sources
          await Future.wait([
            ref.read(newsListProvider.notifier).refresh(),
            ref.read(shortsListProvider.notifier).refresh(),
            ref.refresh(wifiPasswordProvider.future),
          ]);
        },
        child: ListView(
          controller: _scrollController,
          cacheExtent: 500, // Limit the cache to reduce memory usage

          children: [
            SizedBox(height: 16),
            // Always visible banner at the top
            const JupBanner(),
            // WiFi password card (dismissible)
            if (!_wifiPasswordBannerDismissed)
              wifiPasswordAsyncValue.when(
                data: (wifiPassword) {
                  return WifiPasswordBanner(
                    wifiPassword: wifiPassword,
                    onDismiss: _handleWifiPasswordDismiss,
                  ).withPaddingX(16);
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Container(),
              ),
            if (!_wifiPasswordBannerDismissed) const SizedBox(height: 16),
            ShortsPreviewSection(
              onShortTap: (index) {
                context.router.push(ShortsFeedRoute(initialIndex: index));
              },
            ).withPaddingX(16),
            HeadlineSmallEmphasized(text: "News").withPadding(16, 0, 16, 4),
            CategoryDropdown<NewsCategory>(
              categories: const [
                NewsCategory.sport,
                NewsCategory.music,
                NewsCategory.events,
                NewsCategory.food,
                NewsCategory.gaming,
                NewsCategory.other,
              ],
              selectedCategories: selectedNewsFilters,
              labelBuilder: getFilterLabel,
              onToggle: (category) =>
                  ref.read(newsFilterProvider.notifier).toggle(category),
            ).withPadding(16, 0, 16, 4),
            newsAsyncValue.when(
              data: (allNews) {
                final filteredNews = selectedNewsFilters.isEmpty
                    ? allNews
                    : allNews
                        .where(
                          (entry) =>
                              selectedNewsFilters.contains(entry.category),
                        )
                        .toList();

                if (filteredNews.isEmpty) {
                  return EmptyState(
                    title: "Ganz schön leer hier!",
                    message: selectedNewsFilters.isEmpty
                        ? "Hier ist noch nichts los. Schau später nochmal rein, um die neuesten Beiträge und Infos zu sehen!"
                        : "Für die ausgewählten Filter gibt es keine News. Probiere andere Filter aus!",
                  ).withPadding(16, 0, 16, 16);
                }

                final sortedNews = sortWithBadges(filteredNews, seenPosts, (e) => e.documentId, (_) => false);

                final displayedNews = _displayLimit != null
                    ? sortedNews.take(_displayLimit!).toList()
                    : sortedNews;

                return Column(
                  children: [
                    ...displayedNews.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: RepaintBoundary(
                          child: VisibilityDetector(
                            key: Key('news_${entry.documentId}'),
                            onVisibilityChanged: (info) {
                              if (info.visibleFraction > 0.5) {
                                ref.read(seenPostsProvider.notifier).markAsSeen(entry.documentId);
                              }
                            },
                            child: NewsCard(
                              isNew: isNewPost(
                                documentId: entry.documentId,
                                createdAt: entry.createdAt,
                                seenPosts: seenPosts,
                                isLoaded: ref.read(seenPostsProvider.notifier).isLoaded,
                                firstLaunchDate: ref.read(seenPostsProvider.notifier).firstLaunchDate,
                              ),
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
                                context.router.push(
                                  NewsDetailRoute(newsEntry: entry),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_displayLimit != null &&
                        sortedNews.length > _displayLimit!)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_displayLimit == 5) {
                              _displayLimit = 15;
                            } else {
                              _displayLimit = null;
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            const SizedBox(width: 4),
                            LabelLarge(
                              text: _displayLimit == 5
                                  ? 'Mehr laden'
                                  : 'Alle laden',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                  ],
                ).withPaddingX(16);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: ConnectionErrorWidget(
                  errorMessage: error.toString(),
                  onRetry: () => ref.invalidate(newsListProvider),
                ),
              ).withPaddingX(16),
            ),
          ],
        ),
      ),
    );
  }
}
