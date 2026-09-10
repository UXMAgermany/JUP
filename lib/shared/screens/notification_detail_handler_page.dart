import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';

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
      case NotificationType.shorts:
        throw UnsupportedError(
          'NotificationDetailHandlerPage: $type hat keine Detailseite',
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
    context.router.navigate(const NewsOverviewRoute());
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
            // Set the tab stack first so the destination is rendered before
            // this handler is removed — avoids a frame with empty tab content.
            context.router.navigate(
              MainRoute(
                children: [
                  NewsNavigationRoute(
                    children: [
                      const NewsOverviewRoute(),
                      NewsDetailRoute(newsEntry: newsEntry),
                    ],
                  ),
                ],
              ),
            );
            context.router.removeLast();
          });
        }

        // Return loading widget while navigation happens
        return PatternAwareScaffold(
          appBar: _handlerAppBar(context),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => PatternAwareScaffold(
        appBar: _handlerAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => PatternAwareScaffold(
        appBar: _handlerAppBar(
          context,
          title: const Text('Hoppla!'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _navigateToOverview(context),
          ),
        ),
        body: ConnectionErrorWidget(
          errorMessage: 'Irgendwie konnten wir den Eintrag nicht finden...',
          onRetry: () => ref.invalidate(newsDetailProvider(widget.contentId)),
        ),
      ),
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
    context.router.navigate(const EventsOverviewRoute());
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
            // Set the tab stack first so the destination is rendered before
            // this handler is removed — avoids a frame with empty tab content.
            context.router.navigate(
              MainRoute(
                children: [
                  EventsNavigationRoute(
                    children: [
                      const EventsOverviewRoute(),
                      EventDetailRoute(eventEntry: event),
                    ],
                  ),
                ],
              ),
            );
            context.router.removeLast();
          });
        }

        // Return loading widget while navigation happens
        return PatternAwareScaffold(
          appBar: _handlerAppBar(context),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => PatternAwareScaffold(
        appBar: _handlerAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => PatternAwareScaffold(
        appBar: _handlerAppBar(
          context,
          title: const Text('Hoppla!'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _navigateToOverview(context),
          ),
        ),
        body: ConnectionErrorWidget(
          errorMessage: 'Irgendwie konnten wir den Eintrag nicht finden...',
          onRetry: () => ref.invalidate(eventDetailProvider(widget.contentId)),
        ),
      ),
    );
  }
}

/// AppBar für die Handler-Zwischenseiten. Setzt `systemOverlayStyle` wie
/// [SubPageAppBar], das hier nicht passt, weil der Fehlerzweig ein
/// Schließen-Icon statt des Zurück-Pfeils braucht.
AppBar _handlerAppBar(BuildContext context, {Widget? title, Widget? leading}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return AppBar(
    title: title,
    leading: leading,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    ),
  );
}
