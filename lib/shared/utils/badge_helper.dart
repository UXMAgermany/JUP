/// Determines whether a post should show the "Neu!" badge.
///
/// Returns false if:
/// - Seen posts haven't loaded yet or are empty (first install)
/// - The post was created before the app's first launch
/// - The post is older than 7 days
/// - The post has already been seen
bool isNewPost({
  required String documentId,
  required DateTime createdAt,
  required Set<String> seenPosts,
  required bool isLoaded,
  required DateTime? firstLaunchDate,
}) {
  if (!isLoaded || seenPosts.isEmpty) return false;
  if (firstLaunchDate != null && createdAt.isBefore(firstLaunchDate)) {
    return false;
  }
  if (DateTime.now().difference(createdAt).inDays > 7) return false;
  return !seenPosts.contains(documentId);
}
