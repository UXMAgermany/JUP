import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/services/api_client.dart';

/// Submit-state notifier for the admin Event-create flow.
///
/// Builds a single multipart request against `POST /api/events/atomic`:
/// the JSON `data` payload references uploaded files via `__mediaIndex`
/// placeholders, and the actual files travel as `heroImage` + `blockMedia[N]`
/// parts. The CMS uploads them, swaps the placeholders for real media IDs,
/// and creates the event in one step — failing CMS-side rolls back the
/// uploaded files, so no orphan media remains.
class EventCreateNotifier extends StateNotifier<AsyncValue<EventEntry?>> {
  EventCreateNotifier(this._client, this._ref)
    : super(const AsyncValue.data(null));

  final StrapiClient _client;
  final Ref _ref;

  Future<EventEntry?> submit(EventCreateFormState form) async {
    assert(form.category != null, 'submit called before step 1 was valid');
    assert(
      form.startDateTime != null,
      'submit called before step 3 was valid (startDateTime null)',
    );
    state = const AsyncValue.loading();
    try {
      final leadText = form.leadText.trim();
      final blockMedia = <File>[];
      final blocks = <Map<String, dynamic>>[
        {'__component': 'event.text-block', 'body': leadText},
      ];
      for (final pending in form.additionalBlocks) {
        switch (pending) {
          case PendingContentTextBlock(body: final body):
            final trimmed = body.trim();
            if (trimmed.isEmpty) continue;
            blocks.add({'__component': 'event.text-block', 'body': trimmed});
          case PendingContentMediaBlock(file: final file):
            final index = blockMedia.length;
            blockMedia.add(file);
            blocks.add({
              '__component': 'event.media-block',
              '__mediaIndex': index,
            });
        }
      }

      final data = <String, dynamic>{
        'title': form.title.trim(),
        'category': form.category!.toJson(),
        'location': form.location.trim(),
        'startTime': form.startDateTime!.toUtc().toIso8601String(),
        'contentBlocks': blocks,
      };
      if (leadText.isNotEmpty) {
        data['text'] = leadText;
      }
      final subTitle = form.subTitle.trim();
      if (subTitle.isNotEmpty) {
        data['subTitle'] = subTitle;
      }
      if (form.repeatsEnabled && form.repeats != null) {
        data['repeats'] = form.repeats!.toJson();
      }
      if (form.publishLater && form.publishAt != null) {
        data['publishAt'] = form.publishAt!.toUtc().toIso8601String();
      }
      if (form.expiresAtEnabled && form.expiresAt != null) {
        data['expiresAt'] = form.expiresAt!.toUtc().toIso8601String();
      }
      if (form.signupClosesAtEnabled && form.signupClosesAt != null) {
        // CMS-Feld ist type: date — nur YYYY-MM-DD senden (kein
        // toUtc(), um Tagesverschiebungen durch Zeitzone zu vermeiden).
        data['signupClosesAt'] =
            form.signupClosesAt!.toIso8601String().substring(0, 10);
      }
      if (form.scopeGroupDocumentId != null) {
        data['group'] = form.scopeGroupDocumentId;
      }

      final responseData = await _client.postMultipartWithMedia(
        '/api/events/atomic',
        data: data,
        heroImage: form.heroImage,
        blockMedia: blockMedia,
      );
      final entry = EventEntry.fromJson(responseData, _client.baseUrl);
      state = AsyncValue.data(entry);
      // Refresh the events list so the new entry shows up immediately.
      await _ref.read(eventsListProvider.notifier).refresh();
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

final eventCreateProvider =
    StateNotifierProvider<EventCreateNotifier, AsyncValue<EventEntry?>>((ref) {
      return EventCreateNotifier(ref.watch(strapiClientProvider), ref);
    });
