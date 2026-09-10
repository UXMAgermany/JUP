import 'package:jup/features/groups/models/group_model.dart';

/// Eine Option im Gruppen-Auswahl-Stepper-Schritt.
///
/// - [GlobalScopeOption] entspricht „Alle" — der Beitrag wird ohne
///   Gruppenbindung erstellt und ist global sichtbar. Nur JUZ-Admins
///   bekommen diese Option angeboten.
/// - [GroupScopeOption] bindet den Beitrag an genau eine Gruppe.
sealed class ScopeOption {
  const ScopeOption();

  /// Document-ID der Zielgruppe. `null` bei [GlobalScopeOption].
  String? get groupDocumentId;

  /// Anzeige-Label für den Chip im Stepper-Schritt 1.
  String get displayLabel;

  bool get isGlobal => this is GlobalScopeOption;
}

class GlobalScopeOption extends ScopeOption {
  const GlobalScopeOption();

  @override
  String? get groupDocumentId => null;

  @override
  String get displayLabel => 'Alle';
}

class GroupScopeOption extends ScopeOption {
  final Group group;

  const GroupScopeOption(this.group);

  @override
  String? get groupDocumentId => group.documentId;

  @override
  String get displayLabel => group.name;
}
