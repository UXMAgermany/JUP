import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/groups_controller.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/models/scope_option.dart';
import 'package:jup/shared/services/api_client.dart';

final groupsControllerProvider = Provider<GroupsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return GroupsController(client);
});

class GroupsListNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  GroupsListNotifier(
    this._controller, {
    required this.onlyMine,
    required this.useUserAuth,
  }) : super(const AsyncValue.loading()) {
    refresh();
  }

  final GroupsController _controller;
  final bool onlyMine;
  final bool useUserAuth;

  Future<void> refresh() async {
    // Ohne User-Login liefert `onlyMine` serverseitig garantiert 401 (siehe
    // ctx.unauthorized in jup-cms group.ts) — gar nicht erst anfragen, sondern
    // eine leere Liste zeigen.
    if (onlyMine && !useUserAuth) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final groups = await _controller.fetchGroups(
        onlyMine: onlyMine,
        useUserAuth: useUserAuth,
      );
      state = AsyncValue.data(groups);
    } catch (e, st) {
      debugPrint(
        'Groups list refresh failed (onlyMine=$onlyMine, useUserAuth=$useUserAuth): $e\n$st',
      );
      state = AsyncValue.error(e, st);
    }
  }

  /// Replace a single group entry in-place after a mutation, without
  /// re-fetching the whole list. Toleriert Loading-States, solange bereits
  /// einmal Daten geladen wurden (z.B. Mutation während Refresh läuft).
  void upsert(Group updated) {
    final list = state.asData?.value;
    if (list == null) return;
    final idx = list.indexWhere((g) => g.documentId == updated.documentId);
    state = AsyncValue.data(
      idx == -1
          ? [updated, ...list]
          : (List<Group>.from(list)..[idx] = updated),
    );
  }

  void removeById(String documentId) {
    final list = state.asData?.value;
    if (list == null) return;
    state = AsyncValue.data(
      list.where((g) => g.documentId != documentId).toList(),
    );
  }
}

/// All approved groups (used in the "Alle Gruppen" tab and on the
/// logged-out landing page). Uses User-Auth when logged in so the backend
/// can populate the requester's own `pendingRequests` entry.
final allGroupsProvider =
    StateNotifierProvider<GroupsListNotifier, AsyncValue<List<Group>>>((ref) {
      return GroupsListNotifier(
        ref.watch(groupsControllerProvider),
        onlyMine: false,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Approved groups the current user belongs to + own pending groups.
final myGroupsProvider =
    StateNotifierProvider<GroupsListNotifier, AsyncValue<List<Group>>>((ref) {
      return GroupsListNotifier(
        ref.watch(groupsControllerProvider),
        onlyMine: true,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Standard-Refresh nach einer Gruppen-Mutation (Name/Beschreibung/Bild
/// geändert): Detail-Provider invalidieren und beide Listen neu laden.
/// Von den Edit-Sheets geteilt, damit die Sequenz nur an einer Stelle lebt.
Future<void> refreshGroupProviders(WidgetRef ref, String documentId) async {
  ref.invalidate(groupDetailProvider(documentId));
  await ref.read(myGroupsProvider.notifier).refresh();
  await ref.read(allGroupsProvider.notifier).refresh();
}

/// Single group detail. Auto-disposes so navigating away frees memory.
final groupDetailProvider = FutureProvider.autoDispose.family<Group, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(groupsControllerProvider);
  final isAuthenticated = ref.watch(authProvider).isAuthenticated;
  return controller.fetchGroupById(documentId, useUserAuth: isAuthenticated);
});

/// Whether the current user may create a new group. Drives the "+ Gruppe"
/// FAB visibility and the create-screen gate. JUP admins always may; other
/// users need the `canCreateGroup` flag AND must not already be admin of
/// any group (one-group-per-user rule). Backend remains the source of
/// truth — atomic create rejects with 403 even if the client guesses wrong.
final canUserCreateGroupProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  if (user.isJUPAdmin) return true;
  if (!user.canCreateGroup) return false;
  final userDocumentId = user.documentId;
  if (userDocumentId == null) return false;
  return ref
      .watch(myGroupsProvider)
      .maybeWhen(
        data: (groups) => !groups.any((g) => g.isAdmin(userDocumentId)),
        orElse: () => false,
      );
});

/// Gruppen-Optionen für den „Gruppe ▾"-Filter der Feature-Overviews
/// (News, Events, Umfragen).
///
/// JUZ-Admins sehen Inhalte aus allen Gruppen (Moderations-Override) —
/// ihre Filterliste ist deshalb die Discovery-Liste, ergänzt um die eigenen
/// Hidden Groups: die liefert die Discovery nie, als Mitglied soll man nach
/// ihnen aber filtern können. Normale User bekommen „Meine Gruppen"
/// unverändert (enthält Hidden Groups bereits; für andere Gruppen liefert
/// das Backend ohnehin nichts).
final groupFilterOptionsProvider = Provider<List<Group>>((ref) {
  final isJUPAdmin = ref.watch(authProvider).user?.isJUPAdmin ?? false;
  final myGroups = ref
      .watch(myGroupsProvider)
      .maybeWhen(data: (g) => g, orElse: () => const <Group>[]);
  if (!isJUPAdmin) return myGroups;

  final allGroups = ref
      .watch(allGroupsProvider)
      .maybeWhen(data: (g) => g, orElse: () => const <Group>[]);
  final knownIds = allGroups.map((g) => g.documentId).toSet();
  return [
    ...allGroups,
    ...myGroups.where((g) => g.isHidden && !knownIds.contains(g.documentId)),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Liste der Gruppen, in denen der eingeloggte User Admin ist.
/// Leer wenn nicht eingeloggt oder `myGroupsProvider` noch nicht geladen.
final myAdminGroupsProvider = Provider<List<Group>>((ref) {
  final user = ref.watch(authProvider).user;
  final docId = user?.documentId;
  if (docId == null) return const [];
  return ref
      .watch(myGroupsProvider)
      .maybeWhen(
        data: (groups) => groups.where((g) => g.isAdmin(docId)).toList(),
        orElse: () => const [],
      );
});

/// Ob der eingeloggte User News/Events/Umfragen erstellen darf.
/// True für JUZ-Admins (dürfen global posten) ODER User, die in mindestens
/// einer Gruppe Admin sind. Backend bleibt Source-of-Truth — Atomic-Create
/// lehnt 403 ab, falls die Client-Sicht abweicht.
final canCreateScopedContentProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  if (user.isJUPAdmin) return true;
  return ref.watch(myAdminGroupsProvider).isNotEmpty;
});

/// Verfügbare Auswahloptionen für Stepper-Schritt 1 „Für wen erstellst du …?".
///
/// - JUZ-Admin → „Alle" + Admin-Gruppen.
/// - Group-Admin ohne JUZ-Admin-Status → nur Admin-Gruppen (kein „Alle").
/// - User ohne Create-Berechtigung → leere Liste.
final scopeOptionsProvider = Provider<List<ScopeOption>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return const [];
  final adminGroups = ref.watch(myAdminGroupsProvider);
  return [
    if (user.isJUPAdmin) const GlobalScopeOption(),
    ...adminGroups.map(GroupScopeOption.new),
  ];
});
