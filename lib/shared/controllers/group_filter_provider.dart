import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Veralteter Sentinel-Wert für „nur globale Beiträge zeigen". Die Option
/// wurde aus dem UI entfernt; die Konstante dient nur noch der Migration in
/// `_load`, um persistierte Altwerte zu bereinigen.
const String _legacyGlobalOnly = '__global_only__';

/// Filter-State für das Group-Dropdown im Feature-Overview.
///
/// `null` = „Alle" (Default): Backend liefert den Default-Mix aus globalen
/// Beiträgen plus Beiträgen aus eigenen Gruppen.
/// sonst = `documentId` der gewählten Gruppe.
///
/// Family-Schlüssel ist der Feature-Name (`'news'`, `'events'`, `'surveys'`),
/// damit jedes Feature seinen eigenen persistenten Filter behält.
class GroupFilterNotifier extends StateNotifier<String?> {
  final String featureKey;

  GroupFilterNotifier(this.featureKey) : super(null) {
    _load();
  }

  String get _prefsKey => 'groupFilter_$featureKey';

  void set(String? value) {
    state = value;
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    // Leerstring nicht als gültiger Wert akzeptieren — bedeutet „nicht
    // gesetzt", weil shared_prefs `null` vs. "" auf manchen Plattformen
    // verschluckt.
    if (raw == null || raw.isEmpty) return;
    // Migration: Die „Nur globale"-Option gibt es nicht mehr. Wer sie zuletzt
    // gewählt hatte, hätte sonst keinen UI-Weg zurück auf „Alle" — daher den
    // Altwert verwerfen und den Pref-Key bereinigen.
    if (raw == _legacyGlobalOnly) {
      await prefs.remove(_prefsKey);
      return;
    }
    state = raw;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final value = state;
    if (value == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, value);
    }
  }
}

final groupFilterProvider =
    StateNotifierProvider.family<GroupFilterNotifier, String?, String>((
      ref,
      featureKey,
    ) {
      return GroupFilterNotifier(featureKey);
    });
