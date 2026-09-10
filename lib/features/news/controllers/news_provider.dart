import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/news_controller.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/controllers/paginated_list_notifier.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the NewsController
final newsControllerProvider = Provider<NewsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return NewsController(client);
});

/// StateNotifier for managing news list with pagination and filtering
class NewsListNotifier extends PaginatedListNotifier<NewsEntry> {
  NewsListNotifier(
    this.controller, {
    NewsCategory? initialCategory,
    required this.useUserAuth,
  })  : _activeCategory = initialCategory,
        super(pageSize: 25) {
    fetchInitial();
  }

  final NewsController controller;

  /// Wird beim Konstruieren am Auth-State festgenagelt. Bei Login/Logout
  /// baut Riverpod den Notifier neu auf, sodass der korrekte Wert greift —
  /// daher kein Setter nötig.
  final bool useUserAuth;
  NewsCategory? _activeCategory;
  String? _activeGroupDocumentId;

  @override
  Future<List<NewsEntry>> fetchPage(int page) {
    return controller.fetchNews(
      category: _activeCategory,
      pageSize: pageSize,
      page: page,
      groupDocumentId: _activeGroupDocumentId,
      useUserAuth: useUserAuth,
    );
  }

  Future<void> fetchNews({NewsCategory? category}) async {
    _activeCategory = category;
    return fetchInitial();
  }

  /// Setzt den Gruppen-Filter und lädt die erste Seite neu.
  /// [groupDocumentId] == null = „Alle".
  Future<void> setGroupFilter({String? groupDocumentId}) async {
    _activeGroupDocumentId = groupDocumentId;
    return fetchInitial();
  }

  @override
  Future<void> refresh() async {
    return fetchInitial();
  }

  void incrementViewCount(String documentId) {
    state.whenData((newsList) {
      final index = newsList.indexWhere((n) => n.documentId == documentId);
      if (index == -1) return;
      final current = newsList[index];
      final newList = List<NewsEntry>.from(newsList);
      newList[index] = current.copyWith(viewCount: current.viewCount + 1);
      state = AsyncValue.data(newList);
    });
  }
}

/// Provider for fetching all news with mutable state
final newsListProvider =
    StateNotifierProvider<NewsListNotifier, AsyncValue<List<NewsEntry>>>((ref) {
      final controller = ref.watch(newsControllerProvider);
      return NewsListNotifier(
        controller,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Provider for fetching news filtered by category
final newsListByCategoryProvider =
    StateNotifierProvider.family<
      NewsListNotifier,
      AsyncValue<List<NewsEntry>>,
      NewsCategory?
    >((ref, category) {
      final controller = ref.watch(newsControllerProvider);
      return NewsListNotifier(
        controller,
        initialCategory: category,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Provider for fetching a single news entry by ID
final newsDetailProvider = FutureProvider.family<NewsEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(newsControllerProvider);
  final useUserAuth = ref.watch(authProvider).isAuthenticated;
  return await controller.fetchNewsById(documentId, useUserAuth: useUserAuth);
});

/// Submit-state notifier for the admin News-create flow.
///
/// Sends a single multipart request to `POST /api/news-posts/atomic`: the
/// JSON `data` payload references uploaded files via `__mediaIndex`
/// placeholders, and the files travel as `heroImage` + `blockMedia[N]`
/// parts. The CMS uploads, substitutes the placeholders, and creates the
/// news entry atomically — on failure all uploaded files are removed, so no
/// orphan media remains.
class NewsCreateNotifier extends StateNotifier<AsyncValue<NewsEntry?>> {
  NewsCreateNotifier(this._client, this._ref)
    : super(const AsyncValue.data(null));

  final StrapiClient _client;
  final Ref _ref;

  Future<NewsEntry?> submit(NewsCreateFormState form) async {
    assert(form.category != null, 'submit called before step 1 was valid');
    state = const AsyncValue.loading();
    try {
      final leadText = form.leadText.trim();
      final blockMedia = <File>[];
      final blocks = <Map<String, dynamic>>[
        {'__component': 'news.text-block', 'body': leadText},
      ];
      for (final pending in form.additionalBlocks) {
        switch (pending) {
          case PendingContentTextBlock(body: final body):
            final trimmed = body.trim();
            if (trimmed.isEmpty) continue;
            blocks.add({'__component': 'news.text-block', 'body': trimmed});
          case PendingContentMediaBlock(file: final file):
            final index = blockMedia.length;
            blockMedia.add(file);
            blocks.add({
              '__component': 'news.media-block',
              '__mediaIndex': index,
            });
        }
      }

      final data = <String, dynamic>{
        'title': form.title.trim(),
        'category': form.category!.toCmsValue(),
        'contentBlocks': blocks,
      };
      if (leadText.isNotEmpty) {
        data['text'] = leadText;
      }
      final introText = form.introText.trim();
      if (introText.isNotEmpty) {
        data['subTitle'] = introText;
      }
      if (form.publishLater && form.publishAt != null) {
        data['publishAt'] = form.publishAt!.toUtc().toIso8601String();
      }
      if (form.scopeGroupDocumentId != null) {
        data['group'] = form.scopeGroupDocumentId;
      }

      final responseData = await _client.postMultipartWithMedia(
        '/api/news-posts/atomic',
        data: data,
        heroImage: form.heroImage,
        blockMedia: blockMedia,
      );
      final entry = NewsEntry.fromJson(responseData, _client.baseUrl);
      state = AsyncValue.data(entry);
      // Refresh the news list so the new entry shows up immediately.
      await _ref.read(newsListProvider.notifier).refresh();
      return entry;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final newsCreateProvider =
    StateNotifierProvider<NewsCreateNotifier, AsyncValue<NewsEntry?>>((ref) {
      return NewsCreateNotifier(ref.watch(strapiClientProvider), ref);
    });
