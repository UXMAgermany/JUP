import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';

/// Wizard-state über die drei Schritte: Name → Bild → Beschreibung.
/// `_unset` Sentinel im copyWith erlaubt explizites Setzen von Nullable-
/// Feldern zurück auf null (z.B. heroImage entfernen).
class GroupCreateFormState {
  final String name;
  final File? heroImage;
  final String description;

  const GroupCreateFormState({
    this.name = '',
    this.heroImage,
    this.description = '',
  });

  bool get isStep1Valid => name.trim().isNotEmpty && name.trim().length <= 60;

  // Bild ist optional — keine Pflicht-Validierung. Getter bleibt erhalten,
  // damit `isReadyToSubmit` semantisch klar dreigeteilt bleibt.
  bool get isStep2Valid => true;

  bool get isStep3Valid {
    final t = description.trim();
    return t.isNotEmpty && t.length <= 700;
  }

  bool get isReadyToSubmit => isStep1Valid && isStep2Valid && isStep3Valid;

  GroupCreateFormState copyWith({
    String? name,
    Object? heroImage = _unset,
    String? description,
  }) {
    return GroupCreateFormState(
      name: name ?? this.name,
      heroImage:
          identical(heroImage, _unset) ? this.heroImage : heroImage as File?,
      description: description ?? this.description,
    );
  }
}

const Object _unset = Object();

class GroupCreateFormController extends StateNotifier<GroupCreateFormState> {
  GroupCreateFormController() : super(const GroupCreateFormState());

  void setName(String value) => state = state.copyWith(name: value);
  void setHeroImage(File? file) => state = state.copyWith(heroImage: file);
  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void reset() => state = const GroupCreateFormState();
}

final groupCreateFormProvider = StateNotifierProvider.autoDispose<
    GroupCreateFormController, GroupCreateFormState>((ref) {
  return GroupCreateFormController();
});
