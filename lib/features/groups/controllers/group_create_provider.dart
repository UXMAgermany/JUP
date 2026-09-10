import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/groups/controllers/group_create_form_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Submit-state notifier for the group-create wizard. Builds a single
/// multipart request against `POST /api/groups/atomic` — the hero image
/// travels as `heroImage`, the CMS creates the group with reviewStatus
/// `pending`, and the creator is auto-set to `admins`/`members`.
class GroupCreateNotifier extends StateNotifier<AsyncValue<Group?>> {
  GroupCreateNotifier(this._client, this._ref)
      : super(const AsyncValue.data(null));

  final StrapiClient _client;
  final Ref _ref;

  Future<Group?> submit(GroupCreateFormState form) async {
    assert(form.isReadyToSubmit, 'submit called before all steps were valid');
    state = const AsyncValue.loading();
    try {
      final data = <String, dynamic>{
        'name': form.name.trim(),
        'description': form.description.trim(),
      };
      final responseData = await _client.postMultipartWithMedia(
        '/api/groups/atomic',
        data: data,
        heroImage: form.heroImage,
      );
      final group = Group.fromJson(responseData, _client.baseUrl);
      state = AsyncValue.data(group);

      // Refresh "Meine Gruppen" so the new pending group shows up immediately.
      await _ref.read(myGroupsProvider.notifier).refresh();
      return group;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final groupCreateProvider =
    StateNotifierProvider<GroupCreateNotifier, AsyncValue<Group?>>((ref) {
  return GroupCreateNotifier(ref.watch(strapiClientProvider), ref);
});
