import 'package:flutter/material.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/shared/widgets/compact_dropdown.dart';
import 'package:jup/shared/widgets/date_picker_field.dart';
import 'package:jup/shared/widgets/text.dart';

class NewsCreateStep4Publish extends StatelessWidget {
  final NewsCreateFormState state;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickDate;
  final ValueChanged<int> onPickHour;
  final ValueChanged<int> onPickMinute;

  const NewsCreateStep4Publish({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onPickDate,
    required this.onPickHour,
    required this.onPickMinute,
  });

  @override
  Widget build(BuildContext context) {
    final dt = state.publishAt;
    final now = DateTime.now();
    // Wenn noch kein Datum gesetzt ist, fällt der Form-Controller beim Setzen
    // von Stunde/Minute auf `DateTime.now()` zurück — also wie heute filtern.
    final effectiveDate = dt ?? now;
    final isToday = effectiveDate.year == now.year &&
        effectiveDate.month == now.month &&
        effectiveDate.day == now.day;

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

    final selectedHour = dt?.hour;
    final hourSelected =
        selectedHour != null && hourValues.contains(selectedHour)
            ? selectedHour
            : null;

    final minuteValues = dt == null ? allMinutes : minutesForHour(dt.hour);
    final snappedMinute = dt == null ? null : (dt.minute ~/ 15) * 15;
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
                      'Soll die News zu einem späteren Zeitpunkt veröffentlicht werden?',
                ),
              ),
              Switch(value: state.publishLater, onChanged: onToggle),
            ],
          ),
          if (state.publishLater) ...[
            const SizedBox(height: 16),
            DatePickerField(
              label: 'Datum',
              value: dt,
              onTap: onPickDate,
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
                    onSelect: onPickHour,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactDropdown<int>(
                    values: minuteValues,
                    selected: minuteSelected,
                    label: 'Minute',
                    formatValue: (v) => v.toString().padLeft(2, '0'),
                    onSelect: onPickMinute,
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
