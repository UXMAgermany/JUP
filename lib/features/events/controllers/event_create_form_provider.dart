import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';

/// State über alle vier Wizard-Schritte hinweg. `_unset`-Sentinel im copyWith
/// erlaubt explizites Setzen von Nullable-Feldern zurück auf null.
class EventCreateFormState {
  // Step Scope (optional, abhängig von User-Rolle)
  final String? scopeGroupDocumentId;
  final bool scopeSelected;

  // Step 1
  final EventCategory? category;

  // Step 2
  final File? heroImage;
  final String title;
  final String subTitle;

  // Step 3
  final String location;
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final bool signupClosesAtEnabled;
  final DateTime? signupClosesAt;
  final bool repeatsEnabled;
  final EventRepeatType? repeats;

  // Step 4
  final String leadText;
  final List<PendingContentBlock> additionalBlocks;
  final bool publishLater;
  final DateTime? publishAt;
  final bool expiresAtEnabled;
  final DateTime? expiresAt;

  const EventCreateFormState({
    this.scopeGroupDocumentId,
    this.scopeSelected = false,
    this.category,
    this.heroImage,
    this.title = '',
    this.subTitle = '',
    this.location = '',
    this.startDate,
    this.startTime,
    this.signupClosesAtEnabled = false,
    this.signupClosesAt,
    this.repeatsEnabled = false,
    this.repeats,
    this.leadText = '',
    this.additionalBlocks = const [],
    this.publishLater = false,
    this.publishAt,
    this.expiresAtEnabled = false,
    this.expiresAt,
  });

  bool get isScopeStepValid => scopeSelected;

  bool get isStep1Valid => category != null;

  bool get isStep2Valid => title.trim().isNotEmpty;

  bool get isStep3Valid {
    if (location.trim().isEmpty) return false;
    if (startDate == null || startTime == null) return false;
    if (repeatsEnabled && repeats == null) return false;
    if (expiresAtEnabled && !repeatsEnabled) return false;
    if (expiresAtEnabled && expiresAt == null) return false;
    if (signupClosesAtEnabled && signupClosesAt == null) return false;
    if (signupClosesAtEnabled &&
        startDate != null &&
        signupClosesAt!.isAfter(startDate!)) {
      return false;
    }
    return true;
  }

  bool get isStep4Valid => leadText.trim().isNotEmpty;

  bool get isStep5Valid => !publishLater || publishAt != null;

  /// Kombiniert [startDate] + [startTime] zu einer einzelnen [DateTime].
  /// Liefert null wenn eine der beiden Komponenten fehlt.
  DateTime? get startDateTime {
    final d = startDate;
    final t = startTime;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  EventCreateFormState copyWith({
    Object? scopeGroupDocumentId = _unset,
    bool? scopeSelected,
    EventCategory? category,
    Object? heroImage = _unset,
    String? title,
    String? subTitle,
    String? location,
    Object? startDate = _unset,
    Object? startTime = _unset,
    bool? signupClosesAtEnabled,
    Object? signupClosesAt = _unset,
    bool? repeatsEnabled,
    Object? repeats = _unset,
    String? leadText,
    List<PendingContentBlock>? additionalBlocks,
    bool? publishLater,
    Object? publishAt = _unset,
    bool? expiresAtEnabled,
    Object? expiresAt = _unset,
  }) {
    return EventCreateFormState(
      scopeGroupDocumentId: identical(scopeGroupDocumentId, _unset)
          ? this.scopeGroupDocumentId
          : scopeGroupDocumentId as String?,
      scopeSelected: scopeSelected ?? this.scopeSelected,
      category: category ?? this.category,
      heroImage: identical(heroImage, _unset)
          ? this.heroImage
          : heroImage as File?,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      location: location ?? this.location,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      startTime: identical(startTime, _unset)
          ? this.startTime
          : startTime as TimeOfDay?,
      signupClosesAtEnabled:
          signupClosesAtEnabled ?? this.signupClosesAtEnabled,
      signupClosesAt: identical(signupClosesAt, _unset)
          ? this.signupClosesAt
          : signupClosesAt as DateTime?,
      repeatsEnabled: repeatsEnabled ?? this.repeatsEnabled,
      repeats: identical(repeats, _unset)
          ? this.repeats
          : repeats as EventRepeatType?,
      leadText: leadText ?? this.leadText,
      additionalBlocks: additionalBlocks ?? this.additionalBlocks,
      publishLater: publishLater ?? this.publishLater,
      publishAt: identical(publishAt, _unset)
          ? this.publishAt
          : publishAt as DateTime?,
      expiresAtEnabled: expiresAtEnabled ?? this.expiresAtEnabled,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
    );
  }
}

const Object _unset = Object();

class EventCreateFormController extends StateNotifier<EventCreateFormState> {
  EventCreateFormController() : super(const EventCreateFormState());

  /// Setzt die Zielgruppe und markiert den Scope-Step als bewusst durchlaufen.
  /// `null` entspricht „Alle" (global).
  void setScope(String? groupDocumentId) {
    state = state.copyWith(
      scopeGroupDocumentId: groupDocumentId,
      scopeSelected: true,
    );
  }

  // Step 1
  void setCategory(EventCategory category) =>
      state = state.copyWith(category: category);

  // Step 2
  void setHeroImage(File? file) => state = state.copyWith(heroImage: file);

  void setTitle(String value) => state = state.copyWith(title: value);

  void setSubTitle(String value) => state = state.copyWith(subTitle: value);

  // Step 3
  void setLocation(String value) => state = state.copyWith(location: value);

  void setStartDate(DateTime date) {
    state = state.copyWith(
      startDate: DateTime(date.year, date.month, date.day),
    );
  }

  void setStartTime(TimeOfDay time) => state = state.copyWith(startTime: time);

  /// Aktiviert/deaktiviert das optionale Anmeldeschluss-Datum. Beim
  /// Deaktivieren wird der Wert verworfen.
  void setSignupClosesAtEnabled(bool enabled) {
    state = state.copyWith(
      signupClosesAtEnabled: enabled,
      signupClosesAt: enabled ? state.signupClosesAt : null,
    );
  }

  void setSignupClosesAt(DateTime date) {
    state = state.copyWith(
      signupClosesAt: DateTime(date.year, date.month, date.day),
    );
  }

  /// Aktiviert/deaktiviert die Wiederholungs-Auswahl. Beim Aktivieren wird
  /// ein sinnvoller Default (`weekly`) gesetzt, damit der SegmentedButton
  /// direkt eine Auswahl zeigt. Beim Deaktivieren wird der Wert verworfen;
  /// gleichzeitig wird das Serien-Enddatum (`expiresAt`) gelöscht, da es
  /// semantisch nur für wiederkehrende Events gilt.
  void setRepeatsEnabled(bool enabled) {
    state = state.copyWith(
      repeatsEnabled: enabled,
      repeats: enabled ? (state.repeats ?? EventRepeatType.weekly) : null,
      expiresAtEnabled: enabled ? state.expiresAtEnabled : false,
      expiresAt: enabled ? state.expiresAt : null,
    );
  }

  void setRepeats(EventRepeatType value) =>
      state = state.copyWith(repeats: value);

  // Step 4
  void setLeadText(String value) => state = state.copyWith(leadText: value);

  void addTextBlock() {
    state = state.copyWith(
      additionalBlocks: [
        ...state.additionalBlocks,
        const PendingContentTextBlock(body: ''),
      ],
    );
  }

  void updateTextBlock(int index, String body) {
    final blocks = [...state.additionalBlocks];
    final current = blocks[index];
    if (current is! PendingContentTextBlock) return;
    blocks[index] = current.copyWith(body: body);
    state = state.copyWith(additionalBlocks: blocks);
  }

  void addMediaBlock({required File file, required bool isVideo}) {
    state = state.copyWith(
      additionalBlocks: [
        ...state.additionalBlocks,
        PendingContentMediaBlock(file: file, isVideo: isVideo),
      ],
    );
  }

  void removeBlock(int index) {
    final blocks = [...state.additionalBlocks]..removeAt(index);
    state = state.copyWith(additionalBlocks: blocks);
  }

  void setPublishLater(bool value) {
    state = state.copyWith(
      publishLater: value,
      publishAt: value ? state.publishAt : null,
    );
  }

  void setPublishDate(DateTime date) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(
        date.year,
        date.month,
        date.day,
        base.hour,
        base.minute,
      ),
    );
  }

  void setPublishHour(int hour) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(base.year, base.month, base.day, hour, base.minute),
    );
  }

  void setPublishMinute(int minute) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(base.year, base.month, base.day, base.hour, minute),
    );
  }

  void setExpiresAtEnabled(bool enabled) {
    state = state.copyWith(
      expiresAtEnabled: enabled,
      expiresAt: enabled ? state.expiresAt : null,
    );
  }

  void setExpiresAt(DateTime date) {
    state = state.copyWith(
      expiresAt: DateTime(date.year, date.month, date.day),
    );
  }

  void reset() => state = const EventCreateFormState();
}

final eventCreateFormProvider =
    StateNotifierProvider.autoDispose<
      EventCreateFormController,
      EventCreateFormState
    >((ref) {
      return EventCreateFormController();
    });
