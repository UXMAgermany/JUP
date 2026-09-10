import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/groups/controllers/groups_controller.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/shared/controllers/group_filter_provider.dart';

/// Coordinates membership mutations (join, leave, approve, ...) for a single
/// group. Every mutation receives the fresh server-side group back and pipes
/// it into both list-providers + the detail provider, so the UI updates
/// without an extra fetch round-trip. Hält bewusst keinen eigenen State —
/// Source-of-Truth bleiben die Group-Provider; Fehler propagieren als
/// Exception an den Aufrufer (Snackbar).
class GroupMembershipNotifier {
  GroupMembershipNotifier(this._controller, this._ref, this.documentId);

  final GroupsController _controller;
  final Ref _ref;
  final String documentId;

  Future<void> _run(Future<Group> Function() action) async {
    try {
      final updated = await action();
      _ref.read(allGroupsProvider.notifier).upsert(updated);
      _ref.read(myGroupsProvider.notifier).upsert(updated);
      // Bust the detail provider so the next read returns fresh data.
      _ref.invalidate(groupDetailProvider(documentId));
    } catch (e) {
      // Server-state may have advanced (e.g. join request actually accepted
      // server-side after a stale local snapshot) — resync both lists so the
      // next frame reflects reality. Fire-and-forget: snackbar fires now.
      _ref.read(allGroupsProvider.notifier).refresh();
      _ref.read(myGroupsProvider.notifier).refresh();
      rethrow;
    }
  }

  Future<void> requestJoin() => _run(() => _controller.requestJoin(documentId));
  Future<void> cancelRequest() =>
      _run(() => _controller.cancelRequest(documentId));

  Future<void> leave() async {
    await _run(() => _controller.leave(documentId));
    _onOwnMembershipEnded();
  }

  /// Nach dem Austritt verliert der User die Sicht auf Gruppen-Content —
  /// die Content-Listen müssen refetchen. Zeigt ein Feature-Filter noch auf
  /// die verlassene Gruppe, wird er auf „Alle" zurückgesetzt, sonst bliebe
  /// eine tote Gruppen-ID in den Prefs aktiv (dauerhaft leere Liste).
  void _onOwnMembershipEnded() {
    for (final feature in const ['news', 'events', 'surveys']) {
      if (_ref.read(groupFilterProvider(feature)) == documentId) {
        _ref.read(groupFilterProvider(feature).notifier).set(null);
      }
    }
    // Direkt auf den Notifiern refetchen statt auf die Page-Listener der
    // Filter-Provider zu vertrauen — die feuern nur auf gemounteten Screens.
    _ref
        .read(newsListProvider.notifier)
        .setGroupFilter(
          groupDocumentId: _ref.read(groupFilterProvider('news')),
        );
    _ref
        .read(eventsListProvider.notifier)
        .setGroupFilter(
          groupDocumentId: _ref.read(groupFilterProvider('events')),
        );
    _ref
        .read(surveysListProvider.notifier)
        .setGroupFilter(
          groupDocumentId: _ref.read(groupFilterProvider('surveys')),
        );
  }

  Future<void> approve(String userDocumentId) =>
      _run(() => _controller.approveRequest(documentId, userDocumentId));
  Future<void> reject(String userDocumentId) =>
      _run(() => _controller.rejectRequest(documentId, userDocumentId));
  Future<void> removeMember(String userDocumentId) =>
      _run(() => _controller.removeMember(documentId, userDocumentId));
  Future<void> promote(String userDocumentId) =>
      _run(() => _controller.promote(documentId, userDocumentId));
  Future<void> demote(String userDocumentId) =>
      _run(() => _controller.demote(documentId, userDocumentId));
}

final groupMembershipProvider =
    Provider.family<GroupMembershipNotifier, String>((ref, documentId) {
      return GroupMembershipNotifier(
        ref.watch(groupsControllerProvider),
        ref,
        documentId,
      );
    });
