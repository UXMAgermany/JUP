import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/news/controllers/news_controller.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/controllers/paginated_list_notifier.dart';
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
