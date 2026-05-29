import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/features/events/controllers/events_controller.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/services/api_client.dart';

/// Submit-state notifier for the admin Event-create flow. Accepts the
/// raw form state, uploads any pending media, maps it to [EventCreateInput]
/// and dispatches to the CMS controller.
class EventCreateNotifier extends StateNotifier<AsyncValue<EventEntry?>> {
  EventCreateNotifier(this._controller, this._client, this._ref)
    : super(const AsyncValue.data(null));

  final EventsController _controller;
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
      int? heroMediaId;
      if (form.heroImage != null) {
        heroMediaId = await _client.uploadFile(form.heroImage!.path);
      }

      final blocks = <EventContentBlock>[
        EventTextBlock(body: form.leadText.trim()),
      ];
      for (final pending in form.additionalBlocks) {
        switch (pending) {
          case PendingContentTextBlock(body: final body):
            final trimmed = body.trim();
            if (trimmed.isEmpty) continue;
            blocks.add(EventTextBlock(body: trimmed));
          case PendingContentMediaBlock(file: final file):
            final mediaId = await _client.uploadFile(file.path);
            blocks.add(EventMediaBlock(mediaId: mediaId));
        }
      }

      final input = EventCreateInput(
        title: form.title.trim(),
        subTitle: form.subTitle.trim().isEmpty ? null : form.subTitle.trim(),
        location: form.location.trim(),
        startTime: form.startDateTime!,
        category: form.category!,
        imageMediaId: heroMediaId,
        repeats: form.repeatsEnabled ? form.repeats : null,
        publishAt: form.publishLater ? form.publishAt : null,
        expiresAt: form.expiresAtEnabled ? form.expiresAt : null,
        contentBlocks: blocks,
      );

      final entry = await _controller.createEvent(input);
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
      return EventCreateNotifier(
        ref.watch(eventsControllerProvider),
        ref.watch(strapiClientProvider),
        ref,
      );
    });
