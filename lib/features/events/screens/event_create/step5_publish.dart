import 'package:flutter/material.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/shared/widgets/compact_dropdown.dart';
import 'package:jup/shared/widgets/date_picker_field.dart';
import 'package:jup/shared/widgets/text.dart';

/// Step 5 des Event-Create-Wizards. Folgt eigenem Figma-Design
/// (Node 61435:86557): Switch „später veröffentlichen?" mit conditional
/// Datum-Picker + Stunden/Minuten-Dropdowns.
class EventCreateStep5Publish extends StatelessWidget {
  final EventCreateFormState state;
  final ValueChanged<bool> onTogglePublishLater;
  final VoidCallback onPickPublishDate;
  final ValueChanged<int> onPickPublishHour;
  final ValueChanged<int> onPickPublishMinute;

  const EventCreateStep5Publish({
    super.key,
    required this.state,
    required this.onTogglePublishLater,
    required this.onPickPublishDate,
    required this.onPickPublishHour,
    required this.onPickPublishMinute,
  });

  @override
  Widget build(BuildContext context) {
    final publishAt = state.publishAt;
    final now = DateTime.now();
    final effectivePublishDate = publishAt ?? now;
    final isToday = effectivePublishDate.year == now.year &&
        effectivePublishDate.month == now.month &&
        effectivePublishDate.day == now.day;

    const allMinutes = <int>[0, 15, 30, 45];

    List<int> minutesForHour(int h) {
      if (!isToday || h > now.hour) return allMinutes;
      if (h < now.hour) return const [];
      return allMinutes.where((m) => m > now.minute).toList();
    }

    final hourValues = List<int>.generate(
      24,
      (i) => i,
    ).where((h) => minutesForHour(h).isNotEmpty).toList();

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: TitleMedium(
                  text:
                      'Soll das Event zu einem späteren Zeitpunkt veröffentlicht werden?',
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
