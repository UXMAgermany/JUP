import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Base class for StateNotifiers that manage paginated lists.
///
/// Subclasses implement [fetchPage] to load a specific page of data.
/// Pagination state (page number, hasMore, loadingMore) is managed here.
abstract class PaginatedListNotifier<T>
    extends StateNotifier<AsyncValue<List<T>>> {
  PaginatedListNotifier({required this.pageSize})
      : super(const AsyncValue.loading());

  final int pageSize;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Fetch a single page of data. Implemented by subclasses.
  Future<List<T>> fetchPage(int page);

  /// Called after items are fetched or combined. Override to apply custom sorting.
  void sortItems(List<T> items) {}

  /// Load the first page, resetting pagination state.
  Future<void> fetchInitial() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    try {
      final items = await fetchPage(_currentPage);
      if (!mounted) return;
      _hasMore = items.length == pageSize;
      sortItems(items);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load the next page and append to the current list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final currentState = state;
    if (currentState is! AsyncData<List<T>>) return;

    _isLoadingMore = true;
    _currentPage++;

    try {
      final newItems = await fetchPage(_currentPage);
      if (!mounted) return;
      _hasMore = newItems.length == pageSize;

      final updatedList = [...currentState.value, ...newItems];
      sortItems(updatedList);
      state = AsyncValue.data(updatedList);
    } catch (e, stack) {
      _currentPage--;
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Refresh by reloading the first page.
  Future<void> refresh() async {
    return fetchInitial();
  }

  /// Replace an item in the current list using a matcher function.
  void updateItemInList(bool Function(T item) matcher, T updatedItem) {
    final currentState = state;
    if (currentState is AsyncData<List<T>>) {
      final updatedList = currentState.value.map((item) {
        return matcher(item) ? updatedItem : item;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}
