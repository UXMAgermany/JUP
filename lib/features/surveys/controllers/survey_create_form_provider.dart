import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/surveys/models/survey_model.dart';

/// State über den gesamten Survey-Create-Wizard hinweg. `_unset`-Sentinel
/// im copyWith erlaubt explizites Zurücksetzen von Nullable-Feldern
/// auf null (z.B. publishAt beim Deaktivieren der Toggle).
class SurveyCreateFormState {
  // Step 1
  final SurveyType? type;

  // Step 2 (nur multiple)
  /// Null = noch nicht gewählt. false = festgelegte Optionen.
  /// true = Freitext-Optionen (User dürfen ergänzen). Bei yesNo/election
  /// immer null (irrelevant).
  final bool? allowCustomOptions;

  // Step Form
  final File? heroImage;
  final String title;
  final String subTitle;

  /// Optionen-Texte für multiple/election. Default zwei leere Slots als
  /// Startzustand (Figma zeigt zwei Eingabefelder).
  final List<String> options;
  final int maxVotes;

  // Step Schedule
  final DateTime? expiresAt;
  final bool publishLater;
  final DateTime? publishAt;

  const SurveyCreateFormState({
    this.type,
    this.allowCustomOptions,
    this.heroImage,
    this.title = '',
    this.subTitle = '',
    this.options = const ['', ''],
    this.maxVotes = 1,
    this.expiresAt,
    this.publishLater = false,
    this.publishAt,
  });

  bool get isStep1Valid => type != null;

  /// Modus-Step nur bei multiple sichtbar. Bei den anderen Typen wird
  /// dieser Step übersprungen, daher trivially gültig.
  bool get isStep2Valid {
    if (type != SurveyType.multiple) return true;
    return allowCustomOptions != null;
  }

  /// Form-Step: Titel ist Pflicht. Bei multiple/election zusätzlich
  /// Options-Regeln (festgelegt: min 2 nicht-leer, freitext: keine
  /// Mindestanzahl) und maxVotes ≥ 1.
  bool get isFormStepValid {
    if (title.trim().isEmpty) return false;
    if (type == SurveyType.yesNo) return true;

    if (type == SurveyType.multiple || type == SurveyType.election) {
      final nonEmptyCount = options.where((o) => o.trim().isNotEmpty).length;
      // Bei festgelegten Optionen (oder Wahl): mindestens 2 nicht-leere
      // Einträge nötig. Bei Freitext-Multiple darf der Ersteller leer
      // lassen.
      final requireOptions =
          type == SurveyType.election || allowCustomOptions == false;
      if (requireOptions && nonEmptyCount < 2) return false;
      if (maxVotes < 1) return false;
    }
    return true;
  }

  bool get isScheduleStepValid {
    if (expiresAt == null) return false;
    if (publishLater && publishAt == null) return false;
    return true;
  }

  SurveyCreateFormState copyWith({
    Object? type = _unset,
    Object? allowCustomOptions = _unset,
    Object? heroImage = _unset,
    String? title,
    String? subTitle,
    List<String>? options,
    int? maxVotes,
    Object? expiresAt = _unset,
    bool? publishLater,
    Object? publishAt = _unset,
  }) {
    return SurveyCreateFormState(
      type: identical(type, _unset) ? this.type : type as SurveyType?,
      allowCustomOptions: identical(allowCustomOptions, _unset)
          ? this.allowCustomOptions
          : allowCustomOptions as bool?,
      heroImage: identical(heroImage, _unset)
          ? this.heroImage
          : heroImage as File?,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      options: options ?? this.options,
      maxVotes: maxVotes ?? this.maxVotes,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      publishLater: publishLater ?? this.publishLater,
      publishAt: identical(publishAt, _unset)
          ? this.publishAt
          : publishAt as DateTime?,
    );
  }
}

const Object _unset = Object();

class SurveyCreateFormController extends StateNotifier<SurveyCreateFormState> {
  SurveyCreateFormController() : super(const SurveyCreateFormState());

  // Step 1
  /// Beim Wechsel des Typs werden modus-/optionen-spezifische Felder
  /// zurückgesetzt, damit z.B. ein vorheriger Freitext-Modus nicht
  /// versehentlich bei einer Wahl mitgeschleppt wird.
  void setType(SurveyType value) {
    state = state.copyWith(
      type: value,
      allowCustomOptions: null,
      options: const ['', ''],
      maxVotes: 1,
    );
  }

  // Step 2 (multiple-only)
  void setAllowCustomOptions(bool value) =>
      state = state.copyWith(allowCustomOptions: value);

  // Step Form
  void setHeroImage(File? file) => state = state.copyWith(heroImage: file);

  void setTitle(String value) => state = state.copyWith(title: value);

  void setSubTitle(String value) => state = state.copyWith(subTitle: value);

  void setOption(int index, String value) {
    final next = [...state.options];
    if (index < 0 || index >= next.length) return;
    next[index] = value;
    state = state.copyWith(options: next);
  }

  void addOption() {
    if (state.options.length >= 20) return;
    state = state.copyWith(options: [...state.options, '']);
  }

  void removeOption(int index) {
    if (state.options.length <= 2) return;
    if (index < 0 || index >= state.options.length) return;
    final next = [...state.options]..removeAt(index);
    state = state.copyWith(options: next);
  }

  void setMaxVotes(int value) {
    if (value < 1) return;
    state = state.copyWith(maxVotes: value);
  }

  // Step Schedule
  void setExpiresAt(DateTime date) {
    state = state.copyWith(
      expiresAt: DateTime(date.year, date.month, date.day),
    );
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

  void reset() => state = const SurveyCreateFormState();
}

final surveyCreateFormProvider =
    StateNotifierProvider.autoDispose<
      SurveyCreateFormController,
      SurveyCreateFormState
    >((ref) {
      return SurveyCreateFormController();
    });
