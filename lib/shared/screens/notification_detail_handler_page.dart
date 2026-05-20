import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/models/notification_model.dart';

/// Page that handles navigation from notifications to detail pages
/// Fetches content by documentId and displays detail page with back navigation to overview
@RoutePage()
class NotificationDetailHandlerPage extends ConsumerWidget {
  final NotificationType type;
  final String contentId;

  const NotificationDetailHandlerPage({
    super.key,
    required this.type,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (type) {
      case NotificationType.news:
        return _NewsDetailHandler(contentId: contentId);
      case NotificationType.events:
        return _EventDetailHandler(contentId: contentId);
      case NotificationType.surveys:
        // Surveys have no detail page — redirect to overview
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.router.navigate(const SurveysNavigationRoute());
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case NotificationType.shorts:
        // Shorts have no detail page — redirect to shorts feed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.router.navigate(
            NewsNavigationRoute(
              children: [ShortsFeedRoute(initialShortsId: contentId)],
            ),
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}

class _NewsDetailHandler extends ConsumerStatefulWidget {
  final String contentId;

  const _NewsDetailHandler({required this.contentId});

  @override
  ConsumerState<_NewsDetailHandler> createState() => _NewsDetailHandlerState();
}

class _NewsDetailHandlerState extends ConsumerState<_NewsDetailHandler> {
  bool _hasNavigated = false;

  void _navigateToOverview(BuildContext context) {
    context.router.navigate(const NewsNavigationRoute());
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsDetailProvider(widget.contentId));

    return newsAsync.when(
      data: (newsEntry) {
        // Only navigate once
        if (!_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Pop the handler page first, then navigate to the proper stack
            context.router.pop();
            context.router.navigate(
              NewsNavigationRoute(
                children: [
                  const NewsOverviewRoute(),
                  NewsDetailRoute(newsEntry: newsEntry),
                ],
              ),
            );
          });
        }

        // Return loading widget while navigation happens
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        // Auto-navigate to overview after showing error
        Future.delayed(const Duration(seconds: 4), () {
          if (context.mounted) {
            _navigateToOverview(context);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hoppla!'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _navigateToOverview(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Irgendwie konnten wir den Eintrag nicht finden...'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToOverview(context),
                  child: const Text('Zurück zur Übersicht'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventDetailHandler extends ConsumerStatefulWidget {
  final String contentId;

  const _EventDetailHandler({required this.contentId});

  @override
  ConsumerState<_EventDetailHandler> createState() =>
      _EventDetailHandlerState();
}

class _EventDetailHandlerState extends ConsumerState<_EventDetailHandler> {
  bool _hasNavigated = false;

  void _navigateToOverview(BuildContext context) {
    context.router.navigate(const EventsNavigationRoute());
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.contentId));

    return eventAsync.when(
      data: (event) {
        // Only navigate once
        if (!_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Pop the handler page first, then navigate to the proper stack
            context.router.pop();
            context.router.navigate(
              EventsNavigationRoute(
                children: [
                  const EventsOverviewRoute(),
                  EventDetailRoute(eventEntry: event),
                ],
              ),
            );
          });
        }

        // Return loading widget while navigation happens
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        // Auto-navigate to overview after showing error
        Future.delayed(const Duration(seconds: 4), () {
          if (context.mounted) {
            _navigateToOverview(context);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hoppla!'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _navigateToOverview(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Irgendwie konnten wir den Eintrag nicht finden...'),
                const SizedBox(height: 8),
                Text(
                  'Weiterleitung zur Übersicht...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToOverview(context),
                  child: const Text('Zurück zur Übersicht'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
