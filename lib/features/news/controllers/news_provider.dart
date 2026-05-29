import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
  NewsListNotifier(this.controller) : super(pageSize: 25) {
    fetchNews();
  }

  final NewsController controller;
  NewsCategory? _activeCategory;

  @override
  Future<List<NewsEntry>> fetchPage(int page) {
    return controller.fetchNews(
      category: _activeCategory,
      pageSize: pageSize,
      page: page,
    );
  }

  Future<void> fetchNews({NewsCategory? category}) async {
    _activeCategory = category;
    return fetchInitial();
  }

  @override
  Future<void> refresh() async {
    return fetchNews(category: _activeCategory);
  }
}

/// Provider for fetching all news with mutable state
final newsListProvider =
    StateNotifierProvider<NewsListNotifier, AsyncValue<List<NewsEntry>>>((ref) {
      final controller = ref.watch(newsControllerProvider);
      return NewsListNotifier(controller);
    });

/// Provider for fetching news filtered by category
final newsListByCategoryProvider =
    StateNotifierProvider.family<
      NewsListNotifier,
      AsyncValue<List<NewsEntry>>,
      NewsCategory?
    >((ref, category) {
      final controller = ref.watch(newsControllerProvider);
      final notifier = NewsListNotifier(controller);
      notifier.fetchNews(category: category);
      return notifier;
    });

/// Provider for fetching a single news entry by ID
final newsDetailProvider = FutureProvider.family<NewsEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(newsControllerProvider);
  return await controller.fetchNewsById(documentId);
});

/// Submit-state notifier for the admin News-create flow. Accepts the
/// raw form state, uploads any pending media, maps it to [NewsCreateInput]
/// and dispatches to the CMS controller.
class NewsCreateNotifier extends StateNotifier<AsyncValue<NewsEntry?>> {
  NewsCreateNotifier(this._controller, this._client, this._ref)
    : super(const AsyncValue.data(null));

  final NewsController _controller;
  final StrapiClient _client;
  final Ref _ref;

  Future<NewsEntry?> submit(NewsCreateFormState form) async {
    assert(form.category != null, 'submit called before step 1 was valid');
    state = const AsyncValue.loading();
    try {
      int? heroMediaId;
      if (form.heroImage != null) {
        heroMediaId = await _client.uploadFile(form.heroImage!.path);
      }

      final blocks = <NewsContentBlock>[
        NewsTextBlock(body: form.leadText.trim()),
      ];
      for (final pending in form.additionalBlocks) {
        switch (pending) {
          case PendingContentTextBlock(body: final body):
            final trimmed = body.trim();
            if (trimmed.isEmpty) continue;
            blocks.add(NewsTextBlock(body: trimmed));
          case PendingContentMediaBlock(file: final file):
            final mediaId = await _client.uploadFile(file.path);
            blocks.add(NewsMediaBlock(mediaId: mediaId));
        }
      }

      final input = NewsCreateInput(
        title: form.title.trim(),
        subTitle: form.introText.trim().isEmpty ? null : form.introText.trim(),
        category: form.category!,
        imageMediaId: heroMediaId,
        publishAt: form.publishLater ? form.publishAt : null,
        contentBlocks: blocks,
      );

      final entry = await _controller.createNews(input);
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
      return NewsCreateNotifier(
        ref.watch(newsControllerProvider),
        ref.watch(strapiClientProvider),
        ref,
      );
    });
