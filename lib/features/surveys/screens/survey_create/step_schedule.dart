import 'package:flutter/material.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/shared/widgets/compact_dropdown.dart';
import 'package:jup/shared/widgets/date_picker_field.dart';
import 'package:jup/shared/widgets/text.dart';

/// Schedule-Step für den Survey-Wizard. Zwei Bereiche:
/// 1. **expiresAt** (immer sichtbar) — Datum bis wann die Umfrage läuft.
/// 2. **publishAt** (conditional via Toggle) — optionaler späterer
///    Veröffentlichungs-Zeitpunkt mit Datum + Stunde + Minute.
///
/// Beide Bereiche auf derselben Seite (kein eigener Step für publishAt),
/// gemäß Figma-Vorgabe (Node 61435:82648).
class SurveyCreateStepSchedule extends StatelessWidget {
  final SurveyCreateFormState state;
  final VoidCallback onPickExpiresAt;
  final ValueChanged<bool> onTogglePublishLater;
  final VoidCallback onPickPublishDate;
  final ValueChanged<int> onPickPublishHour;
  final ValueChanged<int> onPickPublishMinute;

  const SurveyCreateStepSchedule({
    super.key,
    required this.state,
    required this.onPickExpiresAt,
    required this.onTogglePublishLater,
    required this.onPickPublishDate,
    required this.onPickPublishHour,
    required this.onPickPublishMinute,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = state.expiresAt;
    final publishAt = state.publishAt;
    final now = DateTime.now();
    final effectivePublishDate = publishAt ?? now;
    final isToday = effectivePublishDate.year == now.year &&
        effectivePublishDate.month == now.month &&
        effectivePublishDate.day == now.day;

    // 15-Minuten-Steps analog Events (Konsistenz im App-Look).
    const allMinutes = <int>[0, 15, 30, 45];

    List<int> minutesForHour(int h) {
      if (!isToday || h > now.hour) return allMinutes;
      if (h < now.hour) return const [];
      return allMinutes.where((m) => m > now.minute).toList();
    }

    final hourValues = List<int>.generate(24, (i) => i)
        .where((h) => minutesForHour(h).isNotEmpty)
        .toList();

    final selectedHour = publishAt?.hour;
    final hourSelected =
        selectedHour != null && hourValues.contains(selectedHour)
            ? selectedHour
            : null;

    final minuteValues =
        publishAt == null ? allMinutes : minutesForHour(publishAt.hour);
    final snappedMinute =
        publishAt == null ? null : (publishAt.minute ~/ 15) * 15;
    final minuteSelected =
        snappedMinute != null && minuteValues.contains(snappedMinute)
            ? snappedMinute
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TitleMedium(
            text: 'Wähle aus, bis wann die Umfrage laufen soll.',
          ),
          const SizedBox(height: 16),
          DatePickerField(
            label: 'Datum',
            value: expiresAt,
            onTap: onPickExpiresAt,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: TitleMedium(
                  text: 'Soll die Umfrage zu einem späteren Zeitpunkt '
                      'veröffentlicht werden?',
                ),
              ),
              Switch(
                value: state.publishLater,
                onChanged: onTogglePublishLater,
              ),
            ],
          ),
          if (state.publishLater) ...[
            const SizedBox(height: 16),
            DatePickerField(
              label: 'Datum',
              value: publishAt,
              onTap: onPickPublishDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CompactDropdown<int>(
                    values: hourValues,
                    selected: hourSelected,
                    label: 'Stunde',
                    formatValue: (v) => v.toString().padLeft(2, '0'),
                    onSelect: onPickPublishHour,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactDropdown<int>(
                    values: minuteValues,
                    selected: minuteSelected,
                    label: 'Minute',
                    formatValue: (v) => v.toString().padLeft(2, '0'),
                    onSelect: onPickPublishMinute,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
