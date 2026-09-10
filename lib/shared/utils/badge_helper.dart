/// Determines whether a post should show the "Neu!" badge.
///
/// Returns false if:
/// - Seen posts haven't loaded yet (initial frame)
/// - The user is not authenticated yet (no first-login cutoff recorded)
/// - The post was created before the user's first login on this device
/// - The post is older than 7 days
/// - The post has already been seen
bool isNewPost({
  required String documentId,
  required DateTime createdAt,
  required Set<String> seenPosts,
  required bool isLoaded,
  required DateTime? firstLoginAt,
}) {
  if (!isLoaded) return false;
  if (firstLoginAt == null) return false;
  if (createdAt.isBefore(firstLoginAt)) return false;
  if (DateTime.now().difference(createdAt).inDays > 7) return false;
  return !seenPosts.contains(documentId);
}
